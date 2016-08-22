package blang.runtime

import blang.inits.Instantiator
import blang.inits.Instantiators
import blang.inits.PosixParser
import blang.inits.strategies.FullyQualifiedImplementation
import blang.core.Model
import java.util.Optional
import blang.inits.Arg
import java.util.Random
import blang.inits.Default
import java.util.List
import blang.mcmc.Sampler
import java.util.Collections
import blang.inits.Arguments
import blang.runtime.objectgraph.GraphAnalysis
import org.eclipse.xtend.lib.annotations.Data
import org.omg.CORBA.NamedValue
import java.util.ArrayList
import blang.mcmc.SamplerBuilder
import java.io.BufferedWriter
import java.nio.file.Files
import briefj.run.Results
import briefj.CSV
import blang.inits.VariableNamingService
import blang.runtime.objectgraph.ObjectNode

class Runner implements Runnable {
  
  
  static class Options {
    @Arg 
    Model model
    
    @Arg
    MCMCOptions mcmc
  }
  
  static class MCMCOptions {
    @Arg 
    @Default("1")
    Random random
    
    @Arg 
    @Default("10000") 
    int nIterations
    
    @Arg(description = "Thinning period. Should be great or equal to 1 (1 means no thinning)") 
    @Default("1")
    int thinningPeriod
  }
  
  val Options options
  val GraphAnalysis graphAnalysis
  val List<NamedVariable> namedLatentVariables
  
  @Data
  private static class NamedVariable {
    val String name
    val Object variable
  }
  
  new(
    Options options, 
    GraphAnalysis graphAnalysis, 
    VariableNamingService naming
  ) {
    this.options = options
    this.graphAnalysis = graphAnalysis
    namedLatentVariables = setupProcessors(naming)
  }
  
  def static void main(String ... args) {
    val Instantiator instantiator = Instantiators.getDefault()
    val ObservationProcessor initContext = new ObservationProcessor
    instantiator.globals.put(ObservationProcessor::KEY, initContext)
    instantiator.strategies.put(Model, new FullyQualifiedImplementation)
    instantiator.debug = true
    val Optional<Options> options = initModel(instantiator, PosixParser.parse(args)) 
    if (options.present) {
      val GraphAnalysis graphAnalysis = ModelUtils::graphAnalysis(options.get().model, initContext.graphAnalysisInputs)
      ModelUtils::visualizeGraphAnalysis(graphAnalysis, instantiator)
      new Runner(options.get, graphAnalysis, instantiator)
        .run()
    } else {
      println("Error(s) in provided arguments. Report:")
      println(instantiator.lastInitReport)
    }
  }
  
  def List<NamedVariable> setupProcessors(VariableNamingService naming) {
    val List<NamedVariable> result = new ArrayList
    for (ObjectNode<?> variable : graphAnalysis.latentVariables.filter(ObjectNode)) {
      val String name = naming.getName(variable.object)
      result.add(new NamedVariable(name, variable.object))
    }
    return result
  }
  
  def static Optional<Options> initModel(Instantiator instantiator, Arguments parseArgs) {
    val Optional<Options> result =  instantiator.init(Options, parseArgs)
    if (result.isPresent()) {
      // make sure to initialize lazy objects such as Table, 
      // as all variables to be printed will need to be known by the output processor
      result.get().model.components()
    }
    return result 
  }
  
  val public static final String SAMPLE_FILE = "samples.csv"
  override void run() {
    // TODO: some utilities to deal with details of writing to files
    val BufferedWriter writer = Files.newBufferedWriter(Results.getFileInResultFolder(SAMPLE_FILE).toPath) { 
      writer.append("variable,iteration,value\n")
      var List<Sampler> samplers = SamplerBuilder.instantiateSamplers(graphAnalysis) 
      for (var int i=0; i < options.mcmc.nIterations; i++) {
        Collections.shuffle(samplers, options.mcmc.random) 
        for (Sampler s : samplers) s.execute(options.mcmc.random) 
        if (i % options.mcmc.thinningPeriod === 0) {
          System.out.println('''Iteration «i»''')  
          // log the samples
          for (NamedVariable namedVariable : namedLatentVariables) {
            writer.append(namedVariable.name + "," + i + "," + namedVariable.variable.toString() + "\n")
          }
        } 
      }
    } writer.close
  }
  
}
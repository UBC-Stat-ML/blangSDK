package blang.runtime

import blang.inits.parsing.Posix
import blang.core.Model
import java.util.Optional
import blang.inits.Arg
import java.util.Random
import java.util.List
import blang.mcmc.Sampler
import java.util.Collections
import blang.inits.parsing.Arguments
import blang.runtime.objectgraph.GraphAnalysis
import org.eclipse.xtend.lib.annotations.Data
import org.omg.CORBA.NamedValue
import java.util.ArrayList
import blang.mcmc.SamplerBuilder
import java.io.BufferedWriter
import java.nio.file.Files
import briefj.run.Results
import briefj.CSV
import blang.runtime.objectgraph.ObjectNode
import blang.inits.DesignatedConstructor
import blang.inits.ConstructorArg
import blang.inits.Creator
import blang.inits.Creators
import blang.inits.providers.CoreProviders
import blang.utils.Parsers
import blang.core.ModelBuilder
import blang.processing.SimpleCSVWriter
import java.lang.reflect.Field
import blang.core.Param
import java.io.File
import briefj.BriefIO
import briefj.ReflexionUtils

class Runner implements Runnable {
  
  static class Options {
    val Model model
    
    @Arg
    MCMCOptions mcmc
    
    @DesignatedConstructor
    new(@ConstructorArg("model") ModelBuilder builder) {
      this.model = builder.build()
    }
  }
  
  @Data
  static class MCMCOptions {
    val Random random
    val int nIterations
    val int thinningPeriod
    
    @DesignatedConstructor
    def static MCMCOptions build(
      @ConstructorArg(value = "random", description = "Random seed (defaults to 1)")
      Optional<Random> random,
      @ConstructorArg(value = "nIterations", description = "Number of MCMC passes (defaults to 1000)")
      Optional<Integer> nIterations,
      @ConstructorArg(value = "thinningPeriod", description = "Thinning period. Should be great or equal to 1 (1 means no thinning)") 
      Optional<Integer> thinningPeriod
    ) {
      return new MCMCOptions(
        random.orElse(new Random(1)),
        nIterations.orElse(1000),
        thinningPeriod.orElse(1)
      )
    }
  }
  
  val Options options
  val GraphAnalysis graphAnalysis
//  val List<NamedVariable> namedLatentVariables
  
//  @Data
//  private static class NamedVariable {
//    val String name
//    val Object variable
//  }
  
  new(
    Options options, 
    GraphAnalysis graphAnalysis
//    VariableNamingService naming
  ) {
    this.options = options
    this.graphAnalysis = graphAnalysis
//    namedLatentVariables = setupProcessors(naming)
  }
  
  def static void main(String ... args) {
    val Creator creator = Creators::empty()
    creator.addFactories(CoreProviders)
    creator.addFactories(Parsers)
    val ObservationProcessor initContext = new ObservationProcessor
    creator.addGlobal(ObservationProcessor, initContext)
    val Optional<Options> options = initModel(creator, Posix.parse(args)) 
    if (options.present) {
      val GraphAnalysis graphAnalysis = ModelUtils::graphAnalysis(options.get().model, initContext.graphAnalysisInputs)
//      ModelUtils::visualizeGraphAnalysis(graphAnalysis, instantiator)
      new Runner(options.get, graphAnalysis)
        .run()
    } else {
      println("Error(s) in provided arguments. Report:")
      println(creator.fullReport)
    }
  }
  
//  def List<NamedVariable> setupProcessors(VariableNamingService naming) {
//    val List<NamedVariable> result = new ArrayList
//    for (ObjectNode<?> variable : graphAnalysis.latentVariables.filter(ObjectNode)) {
//      val String name = naming.getName(variable.object)
//      result.add(new NamedVariable(name, variable.object))
//    }
//    return result
//  }
  
  def static Optional<Options> initModel(Creator instantiator, Arguments parseArgs) {
    val Optional<Options> result = 
      try {
        Optional.of(instantiator.init(Options, parseArgs))
      } catch (Exception e) {
        Optional.empty
      }
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
    val SimpleCSVWriters writers = createCSVWriters(options.model) { 
//      writer.append("variable,iteration,value\n")
      var List<Sampler> samplers = SamplerBuilder.instantiateSamplers(graphAnalysis) 
      for (var int i=0; i < options.mcmc.nIterations; i++) {
        Collections.shuffle(samplers, options.mcmc.random) 
        for (Sampler s : samplers) s.execute(options.mcmc.random) 
        if (i % options.mcmc.thinningPeriod === 0) {
          System.out.println('''Iteration «i»''')  
          writers.write(i)
          // log the samples
//          for (NamedVariable namedVariable : namedLatentVariables) {
//            writer.append(namedVariable.name + "," + i + "," + namedVariable.variable.toString() + "\n")
//          }
        } 
      }
    } writers.close()
  }
  
  def static SimpleCSVWriters createCSVWriters(Model model) {
    val List<SimpleCSVWriter> writers = new ArrayList
    val List<Object> objects = new ArrayList
    val File variablesFolder = Results.getFolderInResultFolder("samples")
    for (Field f : model.class.declaredFields) {
      if (f.getAnnotation(Param) == null) {
        val File sampleFile = new File(variablesFolder, f.name + ".csv")
        val SimpleCSVWriter writer = new SimpleCSVWriter(BriefIO.output(sampleFile))
        writers.add(writer)
        objects.add(ReflexionUtils.getFieldValue(f, model))
      }
    }
    return new SimpleCSVWriters(writers, objects)
  }
  
  @Data
  static class SimpleCSVWriters {
    val List<SimpleCSVWriter> writers
    val List<Object> objects
    
    def void close() {
      for (writer : writers) {
        writer.close()
      }
    }
    
    def void write(int mcmcIteration) {
      for (var int i = 0; i < writers.size(); i++) {
        val SimpleCSVWriter writer = writers.get(i)
        writer.setPrefix(#[mcmcIteration])
        writer.write(objects.get(i))
      }
    }
    
  }
  
}
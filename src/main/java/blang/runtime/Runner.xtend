package blang.runtime

import blang.core.Model
import blang.core.ModelBuilder
import blang.core.Param
import blang.inits.Arg
import blang.inits.ConstructorArg
import blang.inits.Creator
import blang.inits.Creators
import blang.inits.DesignatedConstructor
import blang.inits.parsing.Arguments
import blang.inits.parsing.Posix
import blang.inits.providers.CoreProviders
import blang.mcmc.Sampler
import blang.mcmc.SamplerBuilder
import blang.processing.SimpleCSVWriter
import blang.runtime.objectgraph.GraphAnalysis
import blang.utils.Parsers
import briefj.BriefIO
import briefj.ReflexionUtils
import briefj.run.Results
import java.io.File
import java.lang.reflect.Field
import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Optional
import java.util.Random
import org.eclipse.xtend.lib.annotations.Data
import ca.ubc.stat.blang.jvmmodel.SingleBlangModelInferrer

class Runner implements Runnable {
  
  static class Options {
    val Model model
    
    @Arg
    MCMCOptions mcmc
    
    @DesignatedConstructor
    new(
      @ConstructorArg(
        value = "model", 
        description = "The model to run (technically, an inner class builder for it, " + 
          "but the suffix '$Builder' can be skipped)"
      ) ModelBuilder builder
    ) {
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
  
  new(
    Options options, 
    GraphAnalysis graphAnalysis
  ) {
    this.options = options
    this.graphAnalysis = graphAnalysis
  }
  
  def static void main(String ... args) {
    fixModelBuilderArgument(args)
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
  
  def static fixModelBuilderArgument(String[] strings) {
    for (var int i = 0; i < strings.size; i++) {
      if (strings.get(i).trim == "--model" && 
          i < strings.size - 1 &&
          !strings.get(i+1).contains('$')
      ) {
        strings.set(i+1, strings.get(i+1) + "$" + SingleBlangModelInferrer.BUILDER_NAME) 
      }
    }
  }
  
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
    val SimpleCSVWriters writers = createCSVWriters(options.model) { 
      var List<Sampler> samplers = SamplerBuilder.instantiateSamplers(graphAnalysis) 
      for (var int i=0; i < options.mcmc.nIterations; i++) {
        Collections.shuffle(samplers, options.mcmc.random) 
        for (Sampler s : samplers) s.execute(options.mcmc.random) 
        if (i % options.mcmc.thinningPeriod === 0) {
          System.out.println('''Pass «i» (computed «i*samplers.size()» moves so far)''')  
          writers.write(i)
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
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
import blang.inits.parsing.ConfigFile
import blang.inits.parsing.QualifiedName

class Runner implements Runnable {
  
  static class Options {
    val Model model
    
    @Arg
    MCMCOptions mcmc
    
    val boolean printAccessibilityGraph
    
    @DesignatedConstructor
    new(
      @ConstructorArg(
        value = "model", 
        description = "The model to run (technically, an inner class builder for it, " + 
          "but the suffix '$Builder' can be skipped)"
      ) ModelBuilder builder,
      
      @ConstructorArg(value = "printAccessibilityGraph", description = "printAccessibilityGraph (default: false)")
      Optional<Boolean> printAccessibilityGraphOptional
      
    ) {
      this.model = builder.build()
      this.printAccessibilityGraph = printAccessibilityGraphOptional.orElse(false)
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
  
  /**
   * Two syntaxes:
   * - simplified: just one args, the model, rest is read from config file
   * - standard
   */
  def private static Arguments parseArguments(String ... args) {
    if (useSimplifiedArguments(args)) {
      // try to read in (else empty)
      val File configFile = new File(CONFIG_FILE_NAME)
      val Arguments fromFile = {
        if (configFile.exists) {
          ConfigFile.parse(configFile)
        } else {
          new Arguments(Optional.empty, QualifiedName.root)
        }
      }
      // add the one argument (after fixing it)
      val String modelString = fixModelBuilderArgument(args.get(0))
      fromFile.setOrCreateChild("model", Collections.singletonList(modelString))
      return fromFile
    } else {
      fixModelBuilderArgument(args)
      return Posix.parse(args)
    }
  }
  val public static final String CONFIG_FILE_NAME = "configuration.txt"
  
  
  def private static boolean useSimplifiedArguments(String ... args) {
    return args.size == 1
  }
  
  def static void main(String ... args) {
    val Arguments parsedArgs = parseArguments(args)
    val Creator creator = Creators::empty()
    creator.addFactories(CoreProviders)
    creator.addFactories(Parsers)
    val Observations initContext = new Observations
    creator.addGlobal(Observations, initContext)
    val Optional<Options> options = initModel(creator, parsedArgs) 
    if (options.present) {
      val GraphAnalysis graphAnalysis = new GraphAnalysis(options.get().model, initContext)
      if (options.get.printAccessibilityGraph) {
        graphAnalysis.exportAccessibilityGraphVisualization(Results.getFileInResultFolder("accessibility-graph.dot"))
        graphAnalysis.exportFactorGraphVisualization(Results.getFileInResultFolder("factor-graph.dot"))
      }
      new Runner(options.get, graphAnalysis)
        .run()
    } else {
      if (useSimplifiedArguments(args) && !new File(CONFIG_FILE_NAME).exists) {
        println("Paste the following into a file called '" + CONFIG_FILE_NAME + "' and uncomment and edit the required missing information:")
      } else {
        println("Error(s) in provided arguments. Report:")
      }
      println(creator.fullReport)
    }
  }
  
  def static String fixModelBuilderArgument(String string) {
    return string + "$" + SingleBlangModelInferrer.BUILDER_NAME
  }
  def static void fixModelBuilderArgument(String[] strings) {
    for (var int i = 0; i < strings.size; i++) {
      if (strings.get(i).trim == "--model" && 
          i < strings.size - 1 &&
          !strings.get(i+1).contains('$')
      ) {
        strings.set(i+1, fixModelBuilderArgument(strings.get(i+1))) 
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
    return result 
  }
  
  val public static final String SAMPLE_FILE = "samples.csv"
  override void run() {
    val SimpleCSVWriters writers = createCSVWriters(options.model) { 
      var List<Sampler> samplers = SamplerBuilder.instantiateSamplers(graphAnalysis, Collections.EMPTY_SET, Collections.EMPTY_SET)  
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
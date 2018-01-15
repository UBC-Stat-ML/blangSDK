package blang.runtime

import blang.core.Model
import blang.core.ModelBuilder
import blang.inits.Arg
import blang.inits.ConstructorArg
import blang.inits.Creator
import blang.inits.Creators
import blang.inits.DefaultValue
import blang.inits.DesignatedConstructor
import blang.inits.GlobalArg
import blang.inits.experiments.Experiment
import blang.inits.experiments.ParsingConfigs
import blang.inits.parsing.Arguments
import blang.inits.parsing.ConfigFile
import blang.inits.parsing.Posix
import blang.inits.parsing.QualifiedName
import blang.inits.providers.CoreProviders
import blang.mcmc.internals.BuiltSamplers
import blang.mcmc.internals.SamplerBuilder
import blang.io.Parsers
import briefj.run.Results
import java.io.File
import java.util.Collections
import java.util.Optional
import bayonet.distributions.Random
import blang.engines.internals.PosteriorInferenceEngine
import blang.engines.internals.factories.SCM
import blang.io.internals.GlobalDataSourceStore
import ca.ubc.stat.blang.jvmmodel.SingleBlangModelInferrer
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.mcmc.internals.SamplerBuilderOptions
import com.google.common.base.Stopwatch
import briefj.BriefIO
import java.util.concurrent.TimeUnit
import java.util.List

class Runner extends Experiment {  // Warning: "blang.runtime.Runner" hard-coded in ca.ubc.stat.blang.StaticJavaUtils
  
  val Model model
  
  @Arg                          @DefaultValue("SCM")
  public PosteriorInferenceEngine engine = new SCM
  
  @Arg                      @DefaultValue("false")
  public boolean printAccessibilityGraph = false
  
  @Arg         @DefaultValue("true")
  public boolean checkIsDAG = true
  
  @Arg                             @DefaultValue("false")
  public boolean skipForwardSamplerConstruction = false
  
  @Arg                   @DefaultValue("1")
  public Random initRandom = new Random(1)
  
  @Arg
  public Optional<List<String>> excludeFromOutput = Optional.empty
  
  @Arg
  public SamplerBuilderOptions samplers = new SamplerBuilderOptions
  
  @Arg(description = "Version of the blang SDK to use (see https://github.com/UBC-Stat-ML/blangSDK/releases), of the form of a git tag x.y.z where x >= 2. If omitted, use the local SDK's 'master' version.")
  public Optional<String> version // Only used when called from Main 
  public static final String VERSION_FIELD_NAME = "version" 
  
  @GlobalArg
  public Observations observations = new Observations
  
  @DesignatedConstructor
  new(
    @ConstructorArg(value = "model") ModelBuilder builder
  ) {
    this.model = builder.build()
  } 
  
  /**
   * Two syntaxes:
   * - simplified: just one args, the model, rest is read from config file
   * - standard
   */
  def public static Arguments parseArguments(String ... args) {
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
    System::exit(start(args))
  }
  
  def static int start(String ... args) {
    val Arguments parsedArgs = parseArguments(args)
    val Creator creator = Creators::empty()
    creator.addFactories(CoreProviders)
    creator.addFactories(Parsers)
    val Observations observations = new Observations
    creator.addGlobal(Observations, observations)
    val GlobalDataSourceStore globalDS = new GlobalDataSourceStore
    creator.addGlobal(GlobalDataSourceStore, globalDS)
    
    val ParsingConfigs parsingConfigs = new ParsingConfigs
    parsingConfigs.setCreator(creator) 
    parsingConfigs.experimentClass = Runner // needed when called via generated main 
    
    printExplationsIfNeeded(args, parsedArgs, creator)
    
    return Experiment::start(args, parsedArgs, parsingConfigs)
  }
  
  def static void printExplationsIfNeeded(String [] rawArguments, Arguments parsedArgs, Creator creator) {
    if (useSimplifiedArguments(rawArguments) && !new File(CONFIG_FILE_NAME).exists) {
      System.err.println("Configure by pasting command line diagnosis into a file called '" + CONFIG_FILE_NAME + "' and uncomment and edit the required missing information:\n\n")
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
  
  public static class NotDAG extends RuntimeException { new(String s) { super(s) }}
  
  override void run() {
    println("Preprocessing started")
    val Stopwatch preprocessingTime = Stopwatch.createStarted
    samplers.monitoringStatistics = results.child(MONITORING_FOLDER) 
    val GraphAnalysis graphAnalysis = new GraphAnalysis(model, observations)
    engine.check(graphAnalysis)
    if (printAccessibilityGraph) {
      graphAnalysis.exportAccessibilityGraphVisualization(Results.getFileInResultFolder("accessibility-graph.dot"))
      graphAnalysis.exportFactorGraphVisualization(Results.getFileInResultFolder("factor-graph.dot"))
    }
    val BuiltSamplers kernels = SamplerBuilder.build(graphAnalysis, samplers)
    println(kernels)
    if (checkIsDAG) {
      try {
        graphAnalysis.checkDAG
      } catch (RuntimeException re) {
        throw new NotDAG(re.toString + "\nTo disable check for DAG, use the option --checkIsDAG")
      }
    }
    val SampledModel sampledModel = if (skipForwardSamplerConstruction) SampledModel.stripped(graphAnalysis, kernels) else new SampledModel(graphAnalysis, kernels, initRandom)
    engine.sampledModel = sampledModel
    if (excludeFromOutput.present) {
      for (String exclusion : excludeFromOutput.get) {
        val boolean found = sampledModel.objectsToOutput.remove(exclusion) !== null
        if (!found) {
          throw new RuntimeException("In argument excludeFromOutput, did not find a match for " + exclusion)
        }
      }
    }
    preprocessingTime.stop
    val Stopwatch samplingTime = Stopwatch.createStarted
    println("Sampling started")
    engine.performInference
    samplingTime.stop
    reportTiming(preprocessingTime, samplingTime)
  }
  
  def void reportTiming(Stopwatch preprocessingTime, Stopwatch samplingTime) {
    BriefIO.write(results.child(MONITORING_FOLDER).getFileInResultFolder(RUNNING_TIME_SUMMARY), 
      "preprocessingTime_ms\t" + preprocessingTime.elapsed(TimeUnit.MILLISECONDS) + "\n" +
      "samplingTime_ms\t" + samplingTime.elapsed(TimeUnit.MILLISECONDS) + "\n"
    )
    println("Preprocessing time: " + preprocessingTime.toString)
    println("Sampling time: " + samplingTime.toString)
  }
  
  public val static String RUNNING_TIME_SUMMARY = "runningTimeSummary.tsv"
  public val static String LOG_NORM_ESTIMATE = "logNormEstimate.txt"
  public val static String MONITORING_FOLDER = "monitoring"
  public val static String SAMPLES_FOLDER = "samples"
}
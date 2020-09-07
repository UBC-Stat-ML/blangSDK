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
import blang.io.internals.GlobalDataSourceStore
import ca.ubc.stat.blang.jvmmodel.SingleBlangModelInferrer
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.mcmc.internals.SamplerBuilderOptions
import com.google.common.base.Stopwatch
import java.util.concurrent.TimeUnit
import java.util.List
import java.util.ArrayList
import blang.runtime.PostProcessor.NoPostProcessor
import blang.System
import blang.engines.internals.factories.PT
import blang.inits.experiments.ExperimentResults
import blang.inits.InputExceptions.InputException
import blang.engines.internals.factories.MCMC

class Runner extends Experiment {  // Warning: "blang.runtime.Runner" hard-coded in ca.ubc.stat.blang.StaticJavaUtils
  
  public val Model model
  
  @Arg                          @DefaultValue("PT")
  public PosteriorInferenceEngine engine = new PT
  
  @Arg                      @DefaultValue("false")
  public boolean printAccessibilityGraph = false
  
  @Arg         @DefaultValue("true")
  public boolean checkIsDAG = true
  
  @Arg(description = "Stripped means that the construction of forward simulators and annealers is skipped")  
             @DefaultValue("false")
  public boolean stripped = false
  
  @Arg                   @DefaultValue("1")
  public Random initRandom = new Random(1)
  
  @Arg
  public Optional<List<String>> excludeFromOutput = Optional.empty
  
  @Arg
  public SamplerBuilderOptions samplers = new SamplerBuilderOptions
  
  @Arg                         @DefaultValue("false")
  public boolean treatNaNAsNegativeInfinity = false;
  
  @Arg            @DefaultValue("true")
  public boolean annealSupport = true;
  
  @Arg                      @DefaultValue("NoPostProcessor")
  public PostProcessor postProcessor = new NoPostProcessor
  
  @GlobalArg
  public Observations observations = new Observations
  
  @DesignatedConstructor
  new(
    @ConstructorArg(value = "model") ModelBuilder builder
  ) {
    this.model = builder.build()
  } 
  
  /**
   * Create, but does not preprocess/sample/postprocess the runner.
   * Useful for tests, debug, etc.
   */
  def static Runner create(File outputDir, String ... args) {
    outputDir.mkdir
    val Arguments parsedArgs = parseArguments(args)
    val creator = blangCreator
    val results = new ExperimentResults(outputDir)
    creator.addGlobal(ExperimentResults, results)
    try {
      val result = creator.init(Runner, parsedArgs)
      result.results = results
      return result
    } catch (InputException e) {
      System.err.println(creator.fullReport)
      throw e
    }
  }
  
  /**
   * Two syntaxes:
   * - simplified: just one args, the model, rest is read from config file
   * - standard
   */
  def static Arguments parseArguments(String ... args) {
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
      fromFile.getOrCreateDesc(Collections.singletonList("experimentConfigs")).setOrCreateChild("recordGitInfo", Collections.singletonList("false"));
      return fromFile
    } else {
      fixModelBuilderArgument(args)
      return Posix.parse(args)
    }
  }
  val public static String CONFIG_FILE_NAME = "configuration.txt"
  
  def private static boolean useSimplifiedArguments(String ... args) {
    return args.size == 1
  }
  
  def static void main(String ... args) {
    val returnCode = start(args)
    if (returnCode != 0)  
      java.lang.System::exit(returnCode)
  }
  
  def static blangCreator() {
    val Creator creator = Creators::empty()
    creator.addFactories(CoreProviders)
    creator.addFactories(Parsers)
    val Observations observations = new Observations
    creator.addGlobal(Observations, observations)
    val GlobalDataSourceStore globalDS = new GlobalDataSourceStore
    creator.addGlobal(GlobalDataSourceStore, globalDS)
    return creator
  }
  
  def static blangParsingConfigs() {
    val ParsingConfigs parsingConfigs = new ParsingConfigs
    parsingConfigs.setCreator(blangCreator) 
    parsingConfigs.experimentClass = Runner // needed when called via generated main 
    return parsingConfigs
  }
  
  def static int start(String ... args) {
    val Arguments parsedArgs = parseArguments(args)
    printExplationsIfNeeded(args, parsedArgs)
    return Experiment::start(args, parsedArgs, blangParsingConfigs)
  }
  
  def static void printExplationsIfNeeded(String [] rawArguments, Arguments parsedArgs) {
    if (useSimplifiedArguments(rawArguments) && !new File(CONFIG_FILE_NAME).exists) {
      System.err.println("Configure by pasting command line diagnosis into a file called '" + CONFIG_FILE_NAME + "'")
    }
  }
  
  def static String fixModelBuilderArgument(String string) {
    return string.trim.replaceFirst("[.]bl$", "") + "$" + SingleBlangModelInferrer.BUILDER_NAME
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
  
  static class NotDAG extends RuntimeException { new(String s) { super(s) }}
  
  def preprocess() {
    samplers.monitoringStatistics = results.child(MONITORING_FOLDER) 
    val GraphAnalysis graphAnalysis = new GraphAnalysis(model, observations, treatNaNAsNegativeInfinity, annealSupport)
    engine.check(graphAnalysis)
    if (printAccessibilityGraph) {
      graphAnalysis.exportAccessibilityGraphVisualization(Results.getFileInResultFolder("accessibility-graph.dot"))
      graphAnalysis.exportFactorGraphVisualization(Results.getFileInResultFolder("factor-graph.dot"))
    }
    val BuiltSamplers kernels = SamplerBuilder.build(graphAnalysis, samplers)
    System.out.println(kernels)
    if (checkIsDAG) {
      try {
        graphAnalysis.checkDAG
      } catch (RuntimeException re) {
        throw new NotDAG(re.toString + "\nTo disable check for DAG, use the option --checkIsDAG")
      }
    }
    val SampledModel sampledModel = if (stripped) SampledModel.stripped(graphAnalysis, kernels) else new SampledModel(graphAnalysis, kernels, true, true, initRandom)
    if (excludeFromOutput.present) {
      for (String exclusion : excludeFromOutput.get) {
        val boolean found = sampledModel.objectsToOutput.remove(exclusion) !== null
        if (!found) {
          throw new RuntimeException("In argument excludeFromOutput, did not find a match for " + exclusion)
        }
      }
    }
    // remove also fully observed (done after to avoid triggering !found error above)
    for (key : new ArrayList(sampledModel.objectsToOutput.keySet)) {
      val object = sampledModel.objectsToOutput.get(key)
      if (!graphAnalysis.hasAccessibleLatentVariables(object))
        sampledModel.objectsToOutput.remove(key) 
    }
    engine.setSampledModel(sampledModel)
  }
  
  override void run() {
    
    if (engine instanceof MCMC) {
      stripped = true
      checkIsDAG = false
    }
    
    val preprocessTiming = System.out.indentWithTiming("Preprocess") [
      preprocess()
    ].watch
    
    val inferenceTiming = System.out.indentWithTiming("Inference") [ 
      engine.performInference
    ].watch
    
    reportTiming(preprocessTiming, inferenceTiming)
    results.closeAll // need close instead of flush to take into account gz 
    
    System.out.indentWithTiming("Postprocess") [
      postProcess
    ]
  }
  
  def private void postProcess() {
    val _results = results
    postProcessor => [
      results = _results
      blangExecutionDirectory = Optional.of(_results.resultsFolder)
    ]
    postProcessor.run
  }
    
  def void reportTiming(Stopwatch preprocessingTime, Stopwatch samplingTime) {
    val writer = results.child(MONITORING_FOLDER).getAutoClosedBufferedWriter(RUNNING_TIME_SUMMARY)
    writer.append("preprocessingTime_ms\t" + preprocessingTime.elapsed(TimeUnit.MILLISECONDS) + "\n")
    writer.append("samplingTime_ms\t" + samplingTime.elapsed(TimeUnit.MILLISECONDS) + "\n")
  }
  
  public val static String RUNNING_TIME_SUMMARY = "runningTimeSummary.tsv"
  public val static String LOG_NORMALIZATION_ESTIMATE = "logNormalizationEstimate"
    public val static String LOG_NORMALIZATION_ESTIMATOR = "estimator"
  public val static String MONITORING_FOLDER = "monitoring"
  public val static String SAMPLES_FOLDER = "samples"
  
  public val static String sampleColumn = "sample"
}
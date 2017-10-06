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
import java.util.Random
import blang.engines.internals.PosteriorInferenceEngine
import blang.engines.internals.factories.SCM
import blang.io.internals.GlobalDataSourceStore
import ca.ubc.stat.blang.jvmmodel.SingleBlangModelInferrer
import blang.runtime.internals.objectgraph.GraphAnalysis
import java.util.Set
import blang.runtime.internals.UncoveredVariables

class Runner extends Experiment {  // Warning: "blang.runtime.Runner" hard-coded in ca.ubc.stat.blang.StaticJavaUtils
  
  Model model
  
  @Arg                   @DefaultValue("SCM")
  PosteriorInferenceEngine engine = new SCM
  
  @Arg               @DefaultValue("false")
  boolean printAccessibilityGraph = false
  
  @GlobalArg
  Observations observations = new Observations
  
  @Arg(description = "Version of the blang SDK to use (see https://github.com/UBC-Stat-ML/blangSDK/releases), of the form of a git tag x.y.z where x >= 2. If omitted, use the local SDK's 'master' version.")
  public Optional<String> version // Only used when called from Main 
  public static final String VERSION_FIELD_NAME = "version" 
  
  @Arg            @DefaultValue("true")
  boolean checkSamplerCoverage = true
  
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
    
    System::exit(Experiment::start(args, parsedArgs, parsingConfigs))
  }
  
  def static void printExplationsIfNeeded(String [] rawArguments, Arguments parsedArgs, Creator creator) {
    if (!useSimplifiedArguments(rawArguments)) {
      return
    }
    val boolean parsedSuccessfully = try {
      creator.init(Runner, parsedArgs)
      true
    } catch (Exception e) {
      false
    }
    if (!parsedSuccessfully && !new File(CONFIG_FILE_NAME).exists) {
      println("Paste the following into a file called '" + CONFIG_FILE_NAME + "' and uncomment and edit the required missing information:\n\n")
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
  
  val public static final String SAMPLE_FILE = "samples.csv"
  override void run() {
    val GraphAnalysis graphAnalysis = new GraphAnalysis(model, observations)
    engine.check(graphAnalysis)
    if (printAccessibilityGraph) {
      graphAnalysis.exportAccessibilityGraphVisualization(Results.getFileInResultFolder("accessibility-graph.dot"))
      graphAnalysis.exportFactorGraphVisualization(Results.getFileInResultFolder("factor-graph.dot"))
    }
    val BuiltSamplers kernels = SamplerBuilder.build(graphAnalysis)
    println(kernels)
    if (checkSamplerCoverage) {
      val Set<Class<?>> offenders = graphAnalysis.uncoveredVariableTypes(kernels.correspondingVariables)
      if (!offenders.empty) {
        throw new UncoveredVariables(offenders)
      }
    }
    val SampledModel sampledModel = new SampledModel(graphAnalysis, kernels, new Random(1))
    engine.sampledModel = sampledModel
    engine.performInference
  }
}
package blang.runtime.internals

import blang.inits.experiments.Experiment
import blang.inits.Arg
import java.io.File
import briefj.BriefFiles
import blang.inits.experiments.tabwriters.TidySerializer
import blang.core.IntVar
import blang.core.RealVar
import blang.runtime.internals.ComputeESS
import blang.inits.experiments.ExperimentResults
import blang.inits.DefaultValue
import binc.Command
import briefj.BriefIO
import java.util.Map
import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.ComputeESS.EssEstimator
import blang.runtime.PostProcessor
import blang.runtime.Runner
import blang.engines.internals.factories.PT

class DefaultPostProcessor extends PostProcessor {
  
  @Arg   @DefaultValue("Rscript")
  public String rCmd = "Rscript"
  
  @Arg          @DefaultValue("png")
  public String imageFormat = "png"
  
  @Arg            @DefaultValue("0.5")
  public double burnInFraction = 0.5;
  
  @Arg                             @DefaultValue("BATCH")
  public EssEstimator essEstimator = EssEstimator.BATCH;
  
  public static final String ESS_FOLDER = "ess"
  public static final String TRACES_POST_BURN_IN_FOLDER = "traces-post-burnin"
  public static final String TRACES_FULL_FOLDER = "traces-full"
  public static final String POSTERIORS_FOLDER = "posteriors"
  public static final String SUMMARIES_FOLDER = "summaries"
  
  override run() {
    for (posteriorSamples : BriefFiles.ls(new File(blangExecutionDirectory.get, Runner::SAMPLES_FOLDER), "csv")) {
      println("Post-processing " + variableName(posteriorSamples))
      val types = TidySerializer::types(posteriorSamples)
      if (types.containsKey(TidySerializer::VALUE)) {
        val type = types.get(TidySerializer::VALUE)
        // statistics that could make sense for both reals and integers
        if (isIntValued(type) || isRealValued(type)) {
          computeEss(posteriorSamples, results.getFileInResultFolder(ESS_FOLDER))
          createPlot(
            new TracePlot(posteriorSamples, types, this, false),
            results.getFileInResultFolder(TRACES_FULL_FOLDER)
          )
          createPlot(
            new TracePlot(posteriorSamples, types, this, true),
            results.getFileInResultFolder(TRACES_POST_BURN_IN_FOLDER)
          )
          summary(posteriorSamples, types)
        } 
        // statistics for ints only
        if (isIntValued(type)) {
          createPlot(
            new PMFPlot(posteriorSamples, types, this),
            results.getFileInResultFolder(blang.runtime.internals.DefaultPostProcessor.POSTERIORS_FOLDER) 
          )
        }
        // statistics for reals only
        if (isRealValued(type)) {
          createPlot(
            new DensityPlot(posteriorSamples, types, this),
            results.getFileInResultFolder(blang.runtime.internals.DefaultPostProcessor.POSTERIORS_FOLDER) 
          )
        }
      }
    }
    // normalization visualization
    
    
    // some MC diagnostics
    
  }
  
  def static boolean isRealValued(Class<?> type) {
    return type == Double || RealVar.isAssignableFrom(type)
  }
  
  def static boolean isIntValued(Class<?> type) {
    return type == Integer || IntVar.isAssignableFrom(type)
  }
  
  def void computeEss(File posteriorSamples, File essDirectory) {
    val _burnIn = burnInFraction
    val essResults = new ExperimentResults(essDirectory)
    (new ComputeESS => [
      inputFile = posteriorSamples
      results = essResults
      burnInFraction = _burnIn
      estimator = essEstimator
      output = variableName(posteriorSamples) + "-ess.csv"
    ]).run
    essResults.closeAll
  }
  
  def static String variableName(File csvFile) {
    csvFile.name.replaceFirst("[.]csv$", "")
  }
  
  static class TracePlot extends GgPlot {
    val boolean removeBurnIn
    new(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor, boolean removeBurnIn) {
      super(posteriorSamples, types, processor)
      this.removeBurnIn = removeBurnIn
    }
    override ggCommand() {
      val geomString = if (isRealValued(types.get(TidySerializer::VALUE))) "geom_line()" else "geom_step()"
      return (if (removeBurnIn) removeBurnIn() else "") + '''
      
      p <- ggplot(data, aes(x = «Runner::sampleColumn», y = «TidySerializer::VALUE»)) +
        «geomString» + «facetString("scales=\"free\"")»
        theme_bw() + 
        xlab("MCMC iteration") +
        ylab("sample") +
        ggtitle("Trace plot for: «variableName»")
      '''
    }
  }
  
  static class DensityPlot extends GgPlot {
    new(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor) {
      super(posteriorSamples, types, processor)
    }
    override ggCommand() {
      val energyHack = // energy across temperature is very dynamic so truncate the extremes
        if (variableName != PT::energyFileName) 
          "" else '''
        data <- data[data$value < quantile(data$«TidySerializer::VALUE», 0.95), ]
        data <- data[data$value > quantile(data$«TidySerializer::VALUE», 0.05), ]
        ''' 
      return '''
      «removeBurnIn»
      «energyHack»
      p <- ggplot(data, aes(x = «TidySerializer::VALUE»)) +
        geom_density() + «facetString»
        theme_bw() + 
        xlab("«variableName»") +
        ylab("density") +
        ggtitle("Density plot for: «variableName»")
      '''
    }
  }
  
  static class PMFPlot extends GgPlot {
    new(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor) {
      super(posteriorSamples, types, processor)
    }
    override ggCommand() {
      val groupBy = facetVariables => [add(TidySerializer::VALUE)]
      return '''
      «removeBurnIn»
      require("dplyr")
      data <- data %>%
        group_by(«groupBy.join(",")») %>%
        summarise(
          frequency = n()
        )
      
      p <- ggplot(data, aes(x = «TidySerializer::VALUE», y = frequency, xend = «TidySerializer::VALUE», yend = rep(0, length(frequency)))) +
        geom_point() + geom_segment() + «facetString»
        theme_bw() + 
        xlab("«variableName»") +
        ylab("frequency") +
        ggtitle("Probability mass function plot for: «variableName»")
      '''
    }
  }
  
  static abstract class GgPlot {
    public val File posteriorSamples
    public val Map<String,Class<?>> types
    public val String variableName
    public val DefaultPostProcessor processor
    
    new (File posteriorSamples, Map<String,Class<?>> types, DefaultPostProcessor processor) {
      this.posteriorSamples = posteriorSamples
      this.types = types
      this.variableName = variableName(posteriorSamples)
      this.processor = processor
    }
    
    def String removeBurnIn() {
      return '''
      n_samples <- max(data$«Runner.sampleColumn»)
      cut_off <- n_samples * «processor.burnInFraction»
      data <- subset(data, «Runner.sampleColumn» > cut_off)
      '''
    }
    
    def String facetString() { facetString(null) }
    def String facetString(String extraOptions) {
      val facetVariables = facetVariables()
      val secondFacet = if (facetVariables.size == 1) "." else facetVariables.tail.join(" + ")
      return 
        if (facetVariables.empty) 
          "" 
        else 
        '''
          facet_grid(«facetVariables.get(0)» ~ «secondFacet»
          «IF extraOptions !== null», «extraOptions»«ENDIF») + 
        '''
    }
    
    def facetVariables() {
      indices(types)
    }
    
    def String ggCommand() 
  }
  
  def static indices(Map<String,Class<?>> types) {
    types.keySet.filter[it != TidySerializer::VALUE && it != Runner::sampleColumn].toList
  }
  
  def void createPlot(GgPlot plot, File directory) {
    val scriptFile = new File(directory, "." + plot.variableName + ".r")
    val imageFile = new File(directory, plot.variableName + "." + imageFormat)
    
    callR(scriptFile, '''
      require("ggplot2")
      data <- read.csv("«plot.posteriorSamples.absolutePath»")
      «plot.ggCommand»
      ggsave("«imageFile.absolutePath»", limitsize = F)
    ''')
  }
  
  def summary(File posteriorSamples, Map<String, Class<?>> types) {
    val directory = results.getFileInResultFolder(SUMMARIES_FOLDER)
    val variableName = variableName(posteriorSamples)
    val scriptFile = new File(directory, "." + variableName + ".r")
    val groups = indices(types)
    val outputFile = new File(directory, variableName + "-summary.csv")
    callR(scriptFile, '''
      require("dplyr")
      data <- read.csv("«posteriorSamples.absolutePath»")
      summary <- data %>% «IF !groups.empty» group_by(«groups.join(", ")») %>% «ENDIF» 
        summarise( 
          mean = mean(«TidySerializer::VALUE»),
          sd = sd(«TidySerializer::VALUE»),
          min = min(«TidySerializer::VALUE»),
          median = median(«TidySerializer::VALUE»),
          max = max(«TidySerializer::VALUE»)
        )
      write.csv(summary, "«outputFile.absolutePath»")
    ''')
  }
  
  def void callR(File _scriptFile, String commands) {
    val scriptFile = if (_scriptFile === null) BriefFiles.createTempFile() else _scriptFile
    BriefIO.write(scriptFile, commands);
    Command.call(Rscript.appendArg(scriptFile.getAbsolutePath()))
  }
  
  public Command Rscript = Command.cmd(rCmd)
  
  def Document marginalPage() {
    return null
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}
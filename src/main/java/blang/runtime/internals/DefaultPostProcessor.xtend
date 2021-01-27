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
import blang.runtime.internals.ComputeESS.EssEstimator
import blang.runtime.PostProcessor
import blang.runtime.Runner
import blang.engines.internals.factories.PT.Column
import blang.engines.internals.factories.PT.MonitoringOutput
import blang.engines.internals.factories.PT.SampleOutput
import blang.engines.internals.ptanalysis.Paths
import blang.engines.internals.ptanalysis.PathViz
import viz.core.Viz
import java.util.Optional

import static blang.inits.experiments.tabwriters.factories.CSV.*

import blang.runtime.internals.DefaultPostProcessor.Output
import blang.runtime.internals.ComputeESS.Batch
import blang.engines.internals.factories.SCM
import blang.types.SpikedRealVar

class DefaultPostProcessor extends PostProcessor {
  
  @Arg   @DefaultValue("Rscript")
  public String rCmd = "Rscript"
  
  @Arg          @DefaultValue("pdf")
  public String imageFormat = "pdf"
  
  @Arg            @DefaultValue("0.5")
  public double burnInFraction = 0.5

  @Arg            @DefaultValue("0.9")
  public double highestDensityIntervalValue = 0.9
  
  @Arg(description = "In inches")         
               @DefaultValue("2.0")
  public double facetHeight = 2.0
  
  @Arg(description = "In inches")         
              @DefaultValue("4.0")
  public double facetWidth = 4.0
  
  @Arg(description = "Run visualizations based on Processing (may need extra steps to perform in a 'headless' environment)")       
             @DefaultValue("false")
  public boolean runPxviz = false
  
  @Arg            @DefaultValue("false")
  public boolean eleDiagnostic = false
  
  @Arg public Optional<Integer> boldTrajectory = Optional.empty
  
  @Arg                    @DefaultValue("Batch")
  public EssEstimator essEstimator = new Batch
  
  @Arg(description = "A directory containing means and variance estimates from a long run, used to improve ESS estimates; usually of the form /path/to/[longRunId].exec/summaries")
  public Optional<File> referenceSamples = Optional.empty 
  
  static enum Output { ess, tracePlots, tracePlotsFull, posteriorPlots, summaries, monitoringPlots, paths, allEss, autocorrelationFunctions }
  
  def File outputFolder(Output out) { return results.getFileInResultFolder(out.toString) }
  
  public static final String ESS_SUFFIX = "-ess.csv"
  
  var Command _Rscript
  def Command Rscript() {
    if (_Rscript === null)
      _Rscript = Command.cmd(rCmd)
    return _Rscript
  }
  override run() {
    if (!blangExecutionDirectory.present) {
      System.err.println("Set the option --blangExecutionDirectory to a blang exec directory.")
      return
    }
    
    // Note even catching would not work, using System.exit,
    // TODO: fix in pxviz via https://stackoverflow.com/questions/5401281/preventing-system-exit-from-api
    // note comment that the workaround above breaks access to file so need something better clearly
    if (runPxviz) pxviz   
    
    for (posteriorSamples : BriefFiles.ls(new File(blangExecutionDirectory.get, Runner::SAMPLES_FOLDER))) 
      if (posteriorSamples.name.endsWith(".csv") || posteriorSamples.name.endsWith(".csv.gz")) {
        println("Post-processing " + variableName(posteriorSamples))
        val types = TidySerializer::types(posteriorSamples)
        if (types.containsKey(TidySerializer::VALUE)) {
          val type = types.get(TidySerializer::VALUE)
          // statistics that could make sense for both reals and integers
          if (isIntValued(type) || isRealValued(type)) {
            computeEss(posteriorSamples, outputFolder(Output::ess))
            createPlot(
              new TracePlot(posteriorSamples, types, this, false),
              outputFolder(Output::tracePlotsFull)
            )
            createPlot(
              new TracePlot(posteriorSamples, types, this, true),
              outputFolder(Output::tracePlots)
            )
            if (indices(types).empty) { // ACF only available for univariate qts for now
              createPlot(
                new ACFPlot(posteriorSamples, types, this),
                outputFolder(Output::autocorrelationFunctions)
              )
            }
            summary(posteriorSamples, types)
          } 
          // statistics for ints only
          if (isIntValued(type)) {
            createPlot(
              new PMFPlot(posteriorSamples, types, this),
              outputFolder(Output::posteriorPlots)
            )
          }
          // statistics for reals only
          if (isRealValued(type)) {
            createPlot(
              new DensityPlot(posteriorSamples, types, this),
              outputFolder(Output::posteriorPlots)
            )
          }
          if (isSpikeSlab(type)) {
            createPlot(
              new PMFPlot(posteriorSamples, types, this) => [postBurnInExtra = '''data$value <- ifelse(data$value != 0.0, 1.0, 0.0)'''], 
              outputFolder(Output::posteriorPlots),
              "-probabilityNonZero"
            )
          }
        }
    }
    
    println("MC diagnostics")
    
    val monitoringFolder = new File(blangExecutionDirectory.get, Runner::MONITORING_FOLDER)
    
    // for SCM:
    
    simplePlot(csvFile(monitoringFolder, SCM::propagationFileName), SCM::iterationColumn, SCM::annealingParameterColumn)
    simplePlot(csvFile(monitoringFolder, SCM::propagationFileName), SCM::iterationColumn, SCM::essColumn, "-ess")
    simplePlot(csvFile(monitoringFolder, SCM::resamplingFileName), SCM::iterationColumn, SCM::annealingParameterColumn)
    simplePlot(csvFile(monitoringFolder, SCM::resamplingFileName), SCM::iterationColumn, SCM::logNormalizationColumn, "-logNormalization")
    
    // for PT:
    
    for (rateName : #[MonitoringOutput::actualTemperedRestarts, MonitoringOutput::asymptoticRoundTripBound, MonitoringOutput::nonAsymptoticRountTrip])
      simplePlot(csvFile(monitoringFolder, rateName.toString), Column::round, Column::rate)
      
    simplePlot(csvFile(monitoringFolder, MonitoringOutput::swapSummaries.toString), Column::round, Column::average)
    
    for (estimateName : #[MonitoringOutput::globalLambda, MonitoringOutput::logNormalizationContantProgress])
      simplePlot(csvFile(monitoringFolder, estimateName.toString), Column::round, TidySerializer::VALUE)
      
    simplePlot(new File(outputFolder(Output::ess), SampleOutput::energy + ESS_SUFFIX), Column::chain, TidySerializer::VALUE)
    
    for (stat : #[MonitoringOutput::swapStatistics, MonitoringOutput::annealingParameters]) {
      val scale = if (stat == MonitoringOutput::annealingParameters) "scale_y_log10() + " else ""
      plot(csvFile(monitoringFolder, stat.toString), '''
        data <- data[data$isAdapt=="false",]
        p <- ggplot(data, aes(x = «Column::chain», y = «TidySerializer::VALUE»)) +
          geom_point(size = 0.1) + geom_line(alpha = 0.5) +
          ylab("«stat»") + «scale»
          theme_bw()
      ''')
      plot(csvFile(monitoringFolder, stat.toString), '''
        p <- ggplot(data, aes(x = «Column::round», y = «TidySerializer::VALUE», colour = «Column::chain», group = «Column::chain»)) +
          geom_line() +
          ylab("«stat»") + «scale»
          theme_bw()
      ''', "-progress")
    }
    
    plotAdaptationIterations()
    
    for (stat : #[MonitoringOutput::cumulativeLambda, MonitoringOutput::lambdaInstantaneous]) {
      plot(csvFile(monitoringFolder, stat.toString), '''
        data <- data[data$isAdapt=="false",]
        p <- ggplot(data, aes(x = «Column::beta», y = «TidySerializer::VALUE»)) +
          geom_point(size = 0.1) + geom_line(alpha = 0.5) +
          ylab("«stat»") + 
          theme_bw()
      ''')
      plot(csvFile(monitoringFolder, stat.toString), '''
        p <- ggplot(data, aes(x = «Column::beta», y = «TidySerializer::VALUE», colour = «Column::round», group = «Column::round»)) +
          geom_line() +
          ylab("«stat»") + 
          theme_bw()
      ''', "-progress")
    }
    
    if (eleDiagnostic)
      plotELEDiagnostics()
  }
  
  protected def void pxviz() {
    paths()
  }
  
  def void plotAdaptationIterations() {
    val monitoringFolder = new File(blangExecutionDirectory.get, Runner::MONITORING_FOLDER)
    val ratesData = csvFile(monitoringFolder, MonitoringOutput::swapStatistics.toString)
    val paramsData = csvFile(monitoringFolder, MonitoringOutput::annealingParameters.toString)
    if (ratesData === null || paramsData === null) return
    val adaptationIterationsPlotsFolder = new File(outputFolder(Output::monitoringPlots), "adaptationIterations")
    adaptationIterationsPlotsFolder.mkdir
    val rScript = new File(adaptationIterationsPlotsFolder, ".script.r")
    
    callR(rScript, '''
      require("ggplot2")
      require("dplyr")
      allRates <- read.csv("«ratesData.absolutePath»") 
      allParams <- read.csv("«paramsData.absolutePath»") 
      maxRound <- max(allRates$round)
      for (r in 0:maxRound) {
        rates <- allRates %>% filter(round == r)
        params <- allParams %>% filter(round == r)
        rejections <- rev(1 - rates$value)
        cumRejections <- cumsum(rejections)
        empirical <- data.frame("beta" = rev(params$value), "Lambda" = cumRejections)
        p <- ggplot(empirical, aes(x = beta, y = Lambda)) + geom_step(direction="vh") + xlim(0,1) + theme_bw()
        ggsave(paste0("«adaptationIterationsPlotsFolder.absolutePath»/iteration-", r, ".«imageFormat»"), limitsize = F) 
      }
    ''')
  }
  
  def void paths() {
    val monitoringFolder = new File(blangExecutionDirectory.get, Runner::MONITORING_FOLDER)
    val pathsFile = csvFile(monitoringFolder, MonitoringOutput::swapIndicators.toString)
    if (pathsFile !== null && pathsFile.exists) {
      val paths = new Paths(pathsFile.absolutePath, 0, Integer.MAX_VALUE)
      val plotsFolder = outputFolder(Output::monitoringPlots)
      val pViz = new PathViz(paths, Viz::fixHeight(300))
      pViz.boldTrajectory = boldTrajectory
      pViz.output(new File(plotsFolder, Output::paths + ".pdf"))
    }
  }
    
  def void plot(File data, String code) {
    plot(data, code, "")
  }
  
  def void plot(File data, String code, String suffix) {
    if (data === null || !data.exists) {
      return
    }
    val monitoringPlotsFolder = outputFolder(Output::monitoringPlots)
    val name = variableName(data)
    val rScript = new File(monitoringPlotsFolder, "." + name + ".r")
    val output = new File(monitoringPlotsFolder, name + suffix + "." + imageFormat)
    callR(rScript, '''
      require("ggplot2")
      data <- read.csv("«data.absolutePath»")
      «code»
      ggsave("«output.absolutePath»", limitsize = F)
    ''')
  }
  
  def void simplePlot(File data, Object x, Object y) { simplePlot(data, x, y, "") }
  def void simplePlot(File data, Object x, Object y, String suffix) {
    if (data === null) return 
    val name = variableName(data)
    plot(data, '''
      p <- ggplot(data, aes(x = «x», y = «y»)) +
        geom_point(size = 0.1) + geom_line(alpha = 0.5) +
        ylab("«name + " " + y»") + 
        theme_bw()
    ''', suffix)
  }
  
  def plotELEDiagnostics() {
    val samplesDir = new File(blangExecutionDirectory.get, Runner::SAMPLES_FOLDER)
    val energySamples = csvFile(samplesDir, SampleOutput::energy.toString)
    val elePlotsDir = new File(outputFolder(Output::monitoringPlots), "ele")
    elePlotsDir.mkdir
    val rScript = new File(elePlotsDir, ".eleDiagnostics.r") 
    val outputPrefix = elePlotsDir.absolutePath
    callR(rScript, '''
      require("ggplot2")
      require("dplyr")
      require("tidyr")
      data <- read.csv("«energySamples.absolutePath»")
      
      n_samples <- max(data$«Runner.sampleColumn»)
      cut_off <- n_samples * «burnInFraction»
      data <- subset(data, «Runner.sampleColumn» > cut_off)
      
      maxChainIndex <- max(data$chain)
      
      listOfDataFrames <- vector(mode = "list", length = maxChainIndex)
      
      for (c in 1:maxChainIndex) {
        sub <- data %>% filter(chain == c - 1 | chain == c) %>% filter(sample %% 2 == 0) %>% pivot_wider(names_from = «Column::chain», values_from = «TidySerializer::VALUE»)
        
        colnames(sub)[2] <- "colder_chain"
        colnames(sub)[3] <- "warmer_chain"
        
        p <- ggplot(sub, aes(x = colder_chain, y = warmer_chain)) + 
          geom_density_2d() + 
          ggtitle("Interacting energies") +
          theme_bw()  
          
        ggsave(paste0("«outputPrefix»", "/chain_", c-1, "_", c, "_raw.pdf"), p)
        
        # from Bartlett, 1947; Van der Waerden, 1952 "Order tests for the two sample problem and their power", https://cran.r-project.org/web/packages/bestNormalize/vignettes/bestNormalize.html
        sub$transformed_colder_chain <- qnorm((rank(sub$colder_chain) - 0.5)/length(sub$colder_chain))
        sub$transformed_warmer_chain <- qnorm((rank(sub$warmer_chain) - 0.5)/length(sub$warmer_chain))
        
        p <- ggplot(sub, aes(x = transformed_colder_chain, y = transformed_warmer_chain)) + 
          geom_density_2d() + 
          ggtitle("Interacting energies") +
          theme_bw()  
                  
        ggsave(paste0("«outputPrefix»", "/chain_", c-1, "_", c, "_orq.pdf"), p)
        
        listOfDataFrames[[c]] <- sub
      }
      
      all <- bind_rows(listOfDataFrames, .id = "warmer_chain_index")
      
      
      p <- ggplot(all, aes(x = colder_chain, y = warmer_chain)) + 
          geom_density_2d() + 
          ggtitle("Interacting energies") +
          theme_bw()  
                
      ggsave(paste0("«outputPrefix»", "/all_raw.pdf"), p)
      
      p <- ggplot(all, aes(x = transformed_colder_chain, y = transformed_warmer_chain)) + 
        geom_density_2d() + 
        ggtitle("Interacting energies") +
        theme_bw()  
        
      ggsave(paste0("«outputPrefix»", "/all_orq.pdf"), p)
      
      dependences <- all %>% 
        group_by(warmer_chain_index) %>% 
        summarize(correlation = cor(transformed_colder_chain,transformed_warmer_chain)) %>%
        mutate(mutualInformation_oqrApprox = -0.5 * log(1 - correlation^2))
        
      p <- ggplot(dependences, aes(x = as.integer(warmer_chain_index), y = mutualInformation_oqrApprox)) + 
              geom_line() + 
              ggtitle("Mutual information between interacting chain energies") +
              xlab("Warmer chain index") + 
              ylab("Mutual Information (OQR approximation)") + 
              theme_bw()
              
      ggsave(paste0("«outputPrefix»", "/mutualInformation_oqrApprox.pdf"), p)
      
      write.csv(dependences, paste0("«outputPrefix»", "/interactingChainEnergyDependence.csv"))
      
      dependencesSummary <- all %>%  
              summarize(correlation = cor(transformed_colder_chain,transformed_warmer_chain)) %>%
              mutate(mutualInformation_oqrApprox = -0.5 * log(1 - correlation^2))
              
      write.csv(dependencesSummary, paste0("«outputPrefix»", "/interactingChainEnergyDependenceSummary.csv"))
    ''') 
  } 
  
  def static boolean isRealValued(Class<?> type) {
    return type == Double || RealVar.isAssignableFrom(type)
  }
  
  def static boolean isSpikeSlab(Class<?> type) {
    return SpikedRealVar.isAssignableFrom(type)
  }
  
  def static boolean isIntValued(Class<?> type) {
    return type == Integer || IntVar.isAssignableFrom(type)
  }
  
  def void computeEss(File posteriorSamples, File essDirectory) {
    val _burnIn = burnInFraction
    val essResults = new ExperimentResults(essDirectory)
    if (essEstimator instanceof Batch && referenceSamples.isPresent) 
      (essEstimator as Batch).referenceFile = Optional.of(new File(referenceSamples.get, variableName(posteriorSamples) + SUMMARY_SUFFIX))
    val essComputer = new ComputeESS => [
      inputFile = posteriorSamples
      results = essResults
      burnInFraction = _burnIn
      estimator = essEstimator
      output = variableName(posteriorSamples) + ESS_SUFFIX
    ]
    essComputer.run
    essResults.closeAll
    // consolidate all ESS results in one
    val outputFile = new File(outputFolder(Output::ess), essComputer.output)
    for (line : BriefIO.readLines(outputFile).indexCSV)
      results.child(Output::ess.name).getTabularWriter(Output::allEss.name).write(
        "variable" -> variableName(posteriorSamples),
        TidySerializer::VALUE -> line.get(TidySerializer::VALUE)
      )
  }
  
  def static String variableName(File csvFile) {
    return TidySerializer::serializerName(csvFile)   
  }
  
  static class TracePlot extends GgPlot {
    val boolean removeBurnIn
    new(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor, boolean removeBurnIn) {
      super(posteriorSamples, types, processor)
      this.removeBurnIn = removeBurnIn
    }
    override ggCommand() {
      val geomString = if (isRealValued(types.get(TidySerializer::VALUE))) "geom_point(size = 0.1) + geom_line(alpha = 0.5)" else "geom_step()"
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
      return '''
      «removeBurnIn»
      «processor.highestDensityInterval»
      hdi_df <- data %>% group_by(«facetStringName») %>%
       summarise(HDI.lower=hdi_lower(«TidySerializer::VALUE»),
                 HDI.upper=hdi_upper(«TidySerializer::VALUE»))
      
      p <- ggplot(data, aes(x = «TidySerializer::VALUE»)) +
        geom_density() + «facetString»
        theme_bw() + 
        geom_segment(inherit.aes = FALSE, data = hdi_df, aes(x=HDI.lower, xend=HDI.upper, y=0, yend=0), col="red") + 
        geom_point(inherit.aes = FALSE, data = hdi_df, aes(x=HDI.lower, y=0), col="red") + 
        geom_point(inherit.aes = FALSE, data = hdi_df, aes(x=HDI.upper, y=0), col="red") + 
        geom_text(inherit.aes = FALSE, data = hdi_df, aes(y= 0, label="«processor.highestDensityIntervalValue»-HDI", x=(HDI.lower + HDI.upper)/2), vjust=-0.5) +
        xlab("«variableName»") +
        ylab("density") +
        ggtitle("Density plot for: «variableName»")
      '''
    }
  }
  
  static class ACFPlot extends GgPlot {
    new(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor) {
      super(posteriorSamples, types, processor)
    }
    override ggCommand() {
      return '''
      «removeBurnIn»
      
      bacf <- acf(data$«TidySerializer::VALUE», plot = FALSE)
      bacfdf <- with(bacf, data.frame(lag, acf))
      
      p <- ggplot(data = bacfdf, mapping = aes(x = lag, y = acf)) +
             xlab("Lag") +
             ylab("Autocorrelation") +
             ggtitle("Autocorrelation function for: «variableName»") +
             geom_hline(aes(yintercept = 0)) +
             theme_bw() + 
             geom_segment(mapping = aes(xend = lag, yend = 0))
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
      normalization <-  length(unique(data$«Runner.sampleColumn»))
      data <- data %>%
        group_by(«groupBy.join(",")») %>%
        summarise(
          probability = n() / normalization
        )
      «processor.highestDensityInterval»
      hdi_df <- data %>% group_by(«facetStringName») %>%
       summarise(HDI.lower=hdi_lower(«TidySerializer::VALUE»),
                 HDI.upper=hdi_upper(«TidySerializer::VALUE»))
      

      p <- ggplot(data, aes(x = «TidySerializer::VALUE», y = probability, xend = «TidySerializer::VALUE», yend = rep(0, length(probability)))) +
        geom_point() + geom_segment() + «facetString»
        geom_segment(inherit.aes = FALSE, data = hdi_df, aes(x=HDI.lower, xend=HDI.upper, y=0, yend=0), col="red") + 
        geom_point(inherit.aes = FALSE, data = hdi_df, aes(x=HDI.lower, y=0), col="red") + 
        geom_point(inherit.aes = FALSE, data = hdi_df, aes(x=HDI.upper, y=0), col="red") + 
        geom_text(inherit.aes = FALSE, data = hdi_df, aes(y=0, label="«processor.highestDensityIntervalValue»-HDI", x=(HDI.lower + HDI.upper)/2), vjust=-0.5) +
        theme_bw() + 
        xlab("«variableName»") +
        ylab("probability") +
        ggtitle("Probability mass function plot for: «variableName»")
      '''
    }
  }
  
  static abstract class GgPlot {
    public val File posteriorSamples
    public val Map<String,Class<?>> types
    public val String variableName
    public val DefaultPostProcessor processor
    public var String postBurnInExtra = ""
    
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
      «postBurnInExtra»
      '''
    }
    
    
    def String facetStringName() { facetStringName(null) }
    def String facetStringName(String extraOptions) {
      val facetVariables = facetVariables()
      return 
        if (facetVariables.empty) 
        ""
        else 
        '''«facetVariables.get(0)»'''
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
  
  def void createPlot(GgPlot plot, File directory) { createPlot(plot, directory, "")}
  def void createPlot(GgPlot plot, File directory, String suffix) {
    val scriptFile = new File(directory, "." + plot.variableName + suffix + ".r")
    val imageFile = new File(directory, plot.variableName + suffix + "." + imageFormat)
    
    callR(scriptFile, '''
      require("ggplot2")
      require("dplyr")
      
      data <- read.csv("«plot.posteriorSamples.absolutePath»")
      
      # ggplot has bad default sizes for large facetting
      verticalSize <- «facetHeight» * «IF plot.facetVariables.empty» 1 «ELSE» length(unique(data$«plot.facetVariables.get(0)»)) «ENDIF»
      horizontalSize <- «facetWidth»
      «FOR i : 1 ..< plot.facetVariables.size»
      horizontalSize <- horizontalSize * length(unique(data$«plot.facetVariables.get(i)»))
      «ENDFOR»
      
      «plot.ggCommand»
      ggsave("«imageFile.absolutePath»", limitsize = F, height = verticalSize, width = horizontalSize)
    ''')
  }
  
  val static SUMMARY_SUFFIX = "-summary.csv"
  
  def String removeBurnIn() {
    return '''
    n_samples <- max(data$«Runner.sampleColumn»)
    cut_off <- n_samples * «burnInFraction»
    data <- subset(data, «Runner.sampleColumn» > cut_off)
    '''
  }

  def summary(File posteriorSamples, Map<String, Class<?>> types) {
    val directory = outputFolder(Output::summaries)
    val variableName = variableName(posteriorSamples)
    val scriptFile = new File(directory, "." + variableName + ".r")
    val groups = indices(types)
    val outputFile = new File(directory, variableName + "-summary.csv")
    callR(scriptFile, '''
      require("dplyr")
      «highestDensityInterval»
      data <- read.csv("«posteriorSamples.absolutePath»")
      «removeBurnIn»
      summary <- data %>% «IF !groups.empty» group_by(«groups.join(", ")») %>% «ENDIF» 
        summarise( 
          mean = mean(«TidySerializer::VALUE»),
          sd = sd(«TidySerializer::VALUE»),
          min = min(«TidySerializer::VALUE»),
          median = median(«TidySerializer::VALUE»),
          max = max(«TidySerializer::VALUE»),
          HDI.lower = hdi_lower(«TidySerializer::VALUE»),
          HDI.upper = hdi_upper(«TidySerializer::VALUE»)
        )
      write.csv(summary, "«outputFile.absolutePath»")
    ''')
  }

  def String highestDensityInterval() {
    return '''
      hdi_upper <- function(samples) {
      	n = length(samples)
      	m = as.integer(«highestDensityIntervalValue» * n)
      	sorted_samples <- sort(samples)
        shortest_length <- Inf
        shortest_interval <- c()
        for (i in 1:(n-m)){
          lower <- sorted_samples[i]
          upper <- sorted_samples[i+m]
          interval_length <- upper - lower
          if (interval_length < shortest_length) {
            shortest_length <- interval_length
            shortest_interval <- c(lower, upper)
          }
        }
      return (shortest_interval[2])
      }
      hdi_lower <- function(samples) {
      	n = length(samples)
      	m = as.integer(«highestDensityIntervalValue» * n)
      	sorted_samples <- sort(samples)
        shortest_length <- Inf
        shortest_interval <- c()
        for (i in 1:(n-m)){
          lower <- sorted_samples[i]
          upper <- sorted_samples[i+m]
          interval_length <- upper - lower
          if (interval_length < shortest_length) {
            shortest_length <- interval_length
            shortest_interval <- c(lower, upper)
          }
        }
      return (shortest_interval[1])
      }
      '''
    }
    
  
  def void callR(File _scriptFile, String commands) {
    val scriptFile = if (_scriptFile === null) BriefFiles.createTempFile() else _scriptFile
    BriefIO.write(scriptFile, commands);
    Command.call(Rscript.appendArg(scriptFile.getAbsolutePath()))
  }
  
  def static void main(String [] args) {
    Experiment::startAutoExit(args)
  }
}

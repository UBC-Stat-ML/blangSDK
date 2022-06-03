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
  
  @Arg  @DefaultValue("scale_colour_gradient(low = \"blue\", high = \"orange\")")
  public String pathPlotArguments = "scale_colour_gradient(low = \"blue\", high = \"orange\")"
  
  @Arg(description = "A directory containing means and variance estimates from a long run, used to improve ESS estimates; usually of the form /path/to/[longRunId].exec/summaries")
  public Optional<File> referenceSamples = Optional.empty 
  
  static enum Output { ess, tracePlots, tracePlotsFull, posteriorPlots, posteriorECDFs, summaries, monitoringPlots, paths, allEss, autocorrelationFunctions, pathPlots }
  
  def File outputFolder(Output out) { return results.getFileInResultFolder(out.toString) }
  
  public static final String ESS_SUFFIX = "-ess.csv"

  static final double PLOT_SCALE = 3
  static final double PLOT_LONG_SIDE = 16
  static final double PLOT_SHORT_SIDE = 10
  static final String PLOT_UNITS = "cm"
  static final double POINT_SIZE = 0.1
  static final double LINE_ALPHA = 0.5
  
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
    
    val allChainsSamplesFolder = new File(blangExecutionDirectory.get, Runner::SAMPLES_FOR_ALL_CHAINS)
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
            createPlot(
              ecdfPlot(posteriorSamples, types, this),
              outputFolder(Output::posteriorECDFs)
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
              densityPlot(posteriorSamples, types, this),
              outputFolder(Output::posteriorPlots)
            )
            if (allChainsSamplesFolder.exists) {
              val samplesForAllChainsFile = new File(allChainsSamplesFolder, posteriorSamples.name)
              if (samplesForAllChainsFile.exists)
                createPlot(
                  new PathPlot(samplesForAllChainsFile, types, this),
                  outputFolder(Output::pathPlots)
                )
            }
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
    
    ancestryPlots()
    propagationPlots()
    
    // for PT:
    
    for (rateName : #[MonitoringOutput::actualTemperedRestarts, MonitoringOutput::asymptoticRoundTripBound, MonitoringOutput::nonAsymptoticRountTrip])
      simplePlot(csvFile(monitoringFolder, rateName.toString), Column::round, Column::rate)
      
    simplePlot(csvFile(monitoringFolder, MonitoringOutput::swapSummaries.toString), Column::round, Column::average)
    
    for (estimateName : #[MonitoringOutput::globalLambda, MonitoringOutput::logNormalizationConstantProgress])
      simplePlot(csvFile(monitoringFolder, estimateName.toString), Column::round, TidySerializer::VALUE)
      
    simplePlot(new File(outputFolder(Output::ess), SampleOutput::energy + ESS_SUFFIX), Column::chain, TidySerializer::VALUE)
    
    plot(csvFile(monitoringFolder, MonitoringOutput::energyExplCorrelation.toString), '''
      data <- data[data$isAdapt=="false",]
      p <- ggplot(data, aes(x = «Column::beta», y = «TidySerializer::VALUE»)) +
        geom_line() + 
        theme_bw()
    ''')
    
    for (stat : #[MonitoringOutput::swapStatistics, MonitoringOutput::annealingParameters]) {
      val scale = if (stat == MonitoringOutput::annealingParameters) "scale_y_log10() + " else ""
      plot(csvFile(monitoringFolder, stat.toString), '''
        data <- data[data$isAdapt=="false",]
        p <- ggplot(data, aes(x = «Column::chain», y = «TidySerializer::VALUE»)) +
          geom_point(size = «DefaultPostProcessor::POINT_SIZE») + geom_line(alpha = «DefaultPostProcessor::LINE_ALPHA») +
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
          geom_point(size = «DefaultPostProcessor::POINT_SIZE») + geom_line(alpha = «DefaultPostProcessor::LINE_ALPHA») +
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
  
  def void propagationPlots() {
    val monitorDir = new File(blangExecutionDirectory.get, Runner::MONITORING_FOLDER)
    val propagationFile = csvFile(monitorDir, SCM::propagationFileName.toString)
    if (propagationFile === null) return
    val resamplingFile = csvFile(monitorDir, SCM::resamplingFileName.toString)
    val resampled = !(resamplingFile === null)

    val monitorPlotDir = new File(blangExecutionDirectory.get, Output::monitoringPlots.toString)
    val rScript = new File(monitorPlotDir, ".propagation.r")
    val outputPrefix = monitorPlotDir.absolutePath
    callR(rScript, '''
        library("ggplot2")
        library("tidyverse")
        theme_set(theme_bw() + theme(aspect.ratio=1,
                                     legend.direction = "horizontal"))

        propagationDf <- read.csv(paste0("«monitorDir.absolutePath»", "/«SCM::propagationFileName».csv")) %>%
          mutate(time = «SCM::iterationColumn» / max(«SCM::iterationColumn»))
        nIterations <- max(propagationDf$«SCM::iterationColumn»)

        if (nIterations > 0) {

          resampled <- "«resampled»" == "true"
          if (resampled) {
            resamplingDf <- read.csv(paste0("«monitorDir.absolutePath»", "/«SCM::resamplingFileName».csv")) %>%
              mutate(time=«SCM::iterationColumn» / nIterations)
          }

          schedulePlot <- ggplot(propagationDf, aes(x=time, y=«SCM::annealingParameterColumn», colour="Propagation")) +
            geom_point(size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(alpha=«DefaultPostProcessor::LINE_ALPHA») +
            ylab("Annealing parameter") +
            xlab("Time") +
            ylim(c(0, 1)) +
            labs(colour="Statistic") +
            theme(legend.position=c(0.03, 0.97),
                  legend.justification = c("left", "top"))
          if (resampled) {
            schedulePlot <- schedulePlot + geom_point(data=resamplingDf,
             aes(x=time, y=«SCM::annealingParameterColumn», colour="Resampling"),
                 size=«DefaultPostProcessor::POINT_SIZE» * 5)
          }

          histDf <- propagationDf %>%
            mutate(type="Propagation")
          if (resampled) {
            histDf <- histDf %>%
              bind_rows(resamplingDf %>% mutate(type="Resampling"))
          }

          histPlot <- ggplot(histDf, aes(x=«SCM::annealingParameterColumn», group=type, colour=type)) +
            geom_histogram(aes(y=..density..), fill=NA) +
            geom_density(alpha=«DefaultPostProcessor::LINE_ALPHA») +
            guides(fill="none") +
            labs(colour="Histogram") +
            xlab("Annealing parameter") +
            ylab("Density") +
            theme(legend.position=c(0.97, 0.97),
                  legend.justification=c("right", "top"))


          schedGenerator <- splinefun(y = propagationDf$«SCM::iterationColumn», x=propagationDf$«SCM::annealingParameterColumn», method = "monoH.FC")
          xx <- seq(0, 1, by=0.01)
          yy <- schedGenerator(xx, deriv=1)
          derivDf <- data.frame(dTime=yy, beta=xx)

          derivPlot <- ggplot(derivDf, aes(x=beta, y=dTime)) +
            geom_line() +
            xlab("Annealing parameter") +
            ylab("dTime / dBeta") +
            xlim(c(0, 1))

          essPlot <- ggplot(propagationDf, aes(y=«SCM::essColumn»)) +
            geom_point(aes(x=«SCM::annealingParameterColumn», colour="Annealing parameter"), size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(aes(x=«SCM::annealingParameterColumn», colour="Annealing parameter"), alpha=«DefaultPostProcessor::LINE_ALPHA») +
            geom_point(aes(x=time, colour="Iteration (rescaled)"), size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(aes(x=time, colour="Iteration (rescaled)"), alpha=«DefaultPostProcessor::LINE_ALPHA») +
            ylab("ESS") +
            xlab("Time") +
            labs(colour="Time index") +
            guides(alpha="none", size="none") +
            theme(legend.position=c(0.03, 0.03),
                  legend.justification = c("left", "bottom"))


          zPlot <- ggplot(propagationDf, aes(y=«SCM::logNormalizationColumn»)) +
            geom_point(aes(x=«SCM::annealingParameterColumn», colour="Annealing parameter"), size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(aes(x=«SCM::annealingParameterColumn», colour="Annealing parameter"), alpha=«DefaultPostProcessor::LINE_ALPHA») +
            geom_point(aes(x=time, colour="Iteration (rescaled)"), size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(aes(x=time, colour="Iteration (rescaled)"), alpha=«DefaultPostProcessor::LINE_ALPHA») +
            ylab("Log normalization estimate") +
            xlab("Time") +
            labs(colour="Time index") +
            guides(alpha="none", size="none") +
            theme(legend.position=c(0.03, 0.03),
                  legend.justification = c("left", "bottom"))
          if (resampled) {
            zPlot <- zPlot +
              geom_point(data=resamplingDf,
                         aes(x=time, y=«SCM::logNormalizationColumn», colour="Resampling"),
                         size=«DefaultPostProcessor::POINT_SIZE» * 5) +
              geom_point(data=resamplingDf,
                         aes(x=«SCM::annealingParameterColumn», y=«SCM::logNormalizationColumn», colour="Resampling"),
                         size=«DefaultPostProcessor::POINT_SIZE» * 5)
          }

          ratioDf <- propagationDf %>%
            mutate(logRatio = «SCM::logNormalizationColumn» - lag(«SCM::logNormalizationColumn», 1, propagationDf$«SCM::logNormalizationColumn»[1], order_by=«SCM::iterationColumn»))
          if (resampled) {
            ratioDf <- ratioDf %>%
              left_join(resamplingDf %>%
                          rename(resamplingTime=time, resamplingBeta=«SCM::annealingParameterColumn»))
          }

          ratioPlot <- ggplot(ratioDf, aes(y=logRatio)) +
            geom_point(aes(x=«SCM::annealingParameterColumn», colour="Annealing parameter"), size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(aes(x=«SCM::annealingParameterColumn», colour="Annealing parameter"), alpha=«DefaultPostProcessor::LINE_ALPHA») +
            geom_point(aes(x=time, colour="Iteration (rescaled)"), size=«DefaultPostProcessor::POINT_SIZE») +
            geom_line(aes(x=time, colour="Iteration (rescaled)"), alpha=«DefaultPostProcessor::LINE_ALPHA») +
            ylab("Log normalization estimate") +
            xlab("Time") +
            labs(colour="Time index") +
            guides(alpha="none", size="none") +
            theme(legend.position=c(0.03, 0.03),
                  legend.justification = c("left", "bottom"))
          if (resampled) {
            ratioPlot <- ratioPlot +
              geom_point(data=ratioDf,
                         aes(x=resamplingTime, y=logRatio, colour="Resampling"),
                         size=«DefaultPostProcessor::POINT_SIZE» * 5) +
              geom_point(data=ratioDf,
                         aes(x=resamplingBeta, y=logRatio, colour="Resampling"),
                         size=«DefaultPostProcessor::POINT_SIZE» * 5)
          }

          p <- cowplot::plot_grid(schedulePlot, histPlot, derivPlot, zPlot, ratioPlot, essPlot, nrow=2, ncol=3)
          ggsave(paste0("«outputPrefix»", "/«SCM::propagationFileName».pdf"),
            p,
            scale=«DefaultPostProcessor::PLOT_SCALE»,
            width=«DefaultPostProcessor::PLOT_LONG_SIDE»,
            height=«DefaultPostProcessor::PLOT_SHORT_SIDE»,
            units="«DefaultPostProcessor::PLOT_UNITS»")
        }
    ''')
  }

  def void untangleAncestry() {
    val monitorDir = new File(blangExecutionDirectory.get, Runner::MONITORING_FOLDER)
    val ancestryFile = csvFile(monitorDir, SCM::ancestryFileName.toString)
    if (ancestryFile === null) return
    val rScript = new File(monitorDir, ".ancestry-untangle.r")
    callR(rScript, '''
        library("tidyverse")

        tempDf <- read.csv("«ancestryFile.absolutePath»")

        nParticles <- length(unique(tempDf$«SCM::particleColumn»))
        nResamples <- length(unique(tempDf$«SCM::iterationColumn»))
        ancestryDf <- tempDf %>%
          select(-«SCM::annealingParameterColumn») %>%
          arrange(«SCM::particleColumn», «SCM::iterationColumn») %>%
          pivot_wider(id_cols = «SCM::particleColumn», names_from = «SCM::iterationColumn», names_prefix = "«SCM::iterationColumn»_", values_from = «SCM::ancestorColumn») %>%
          column_to_rownames(var="«SCM::particleColumn»")

        ancestryMtx <- as.matrix(ancestryDf, rownames.force = 1)

        resultMtx <- ancestryMtx
        if (nResamples > 1) {
            for (particle in 1:nParticles) {
              resultMtx[particle, 1] <- ancestryMtx[particle, nResamples]
              for (iter in 2:nResamples) {
                resultMtx[particle, iter] <- ancestryMtx[resultMtx[particle, iter - 1] + 1, nResamples - iter + 1]
              }
            }
        }


        tempResultDf <- data.frame(resultMtx)
        resultLong <- tempResultDf %>%
          mutate(«SCM::particleColumn» = as.integer(row.names(tempResultDf))) %>%
          pivot_longer(cols=-c(«SCM::particleColumn»), values_to="«SCM::ancestorColumn»", names_to="«SCM::iterationColumn»", names_prefix="«SCM::iterationColumn»_") %>%
          mutate(«SCM::iterationColumn» = as.integer(«SCM::iterationColumn»)) %>%
          group_by(«SCM::particleColumn») %>%
          arrange(«SCM::iterationColumn») %>%
          mutate(«SCM::iterationColumn»= rev(«SCM::iterationColumn»)) %>%
          ungroup()

        resultDf <- resultLong %>%
          left_join(
            tempDf %>%
            select(-«SCM::ancestorColumn»)
          ) %>%
          pivot_longer(cols=c(«SCM::annealingParameterColumn», «SCM::iterationColumn»), names_to="timeType", values_to="time") %>%
          mutate(particle = particle - 1)
        write.csv(resultDf, paste0("«monitorDir.absolutePath»", "/«SCM::ancestryFileName»-untangled.csv"), row.names=F)

        distinctDf <- resultDf %>%
          group_by(timeType, time) %>%
          distinct(«SCM::ancestorColumn») %>%
          count
        write.csv(distinctDf, paste0("«monitorDir.absolutePath»", "/«SCM::ancestryFileName»-distinct.csv"), row.names=F)
    ''')
  }


  def void ancestryPlots() {
    untangleAncestry()
    val monitorDir = new File(blangExecutionDirectory.get, Runner::MONITORING_FOLDER)
    val ancestryFile = csvFile(monitorDir, SCM::ancestryFileName.toString)
    if (ancestryFile === null) return

    val monitorPlotDir = new File(blangExecutionDirectory.get, Output::monitoringPlots.toString)
    val rScript = new File(monitorPlotDir, ".ancestry-plot.r")
    val outputPrefix = monitorPlotDir.absolutePath
    callR(rScript, '''
        library("ggplot2")
        library("tidyverse")
        theme_set(theme_bw() + theme(legend.position = c(0.03, 0.03),
                                     legend.direction = "horizontal",
                                     legend.justification = "left"))

        distinctDf <- read.csv(paste0("«monitorDir.absolutePath»", "/«SCM::ancestryFileName»-distinct.csv"))
        resultDf <- read.csv(paste0("«monitorDir.absolutePath»", "/«SCM::ancestryFileName»-untangled.csv"))

        nParticles <- length(unique(resultDf$«SCM::particleColumn»))
        facetLabeller <- as_labeller(c("«SCM::annealingParameterColumn»"="Annealing parameter",
                                       "«SCM::iterationColumn»"="Iteration"))

        p1 <- ggplot(distinctDf, aes(x=time, y=n)) +
          geom_point(size=«DefaultPostProcessor::POINT_SIZE») +
          geom_line(alpha=«DefaultPostProcessor::LINE_ALPHA») +
          ylab("Count") +
          xlab("Time") +
          ylim(c(0, nParticles)) +
          facet_wrap(~timeType, scales="free_x", nrow=2, labeller=facetLabeller)

        # TODO: plot distinct lineages without losing segments.
        # simplifiedDf <- resultDf %>% distinct(ancestor, time, .keep_all=T)  # this plot will lose segments
        simplifiedDf <- resultDf
        p2 <- ggplot(simplifiedDf, aes(x=time, y=«SCM::ancestorColumn», group=«SCM::particleColumn», colour=«SCM::particleColumn»)) +
          geom_point(size=«DefaultPostProcessor::POINT_SIZE») +
          geom_line(alpha=«DefaultPostProcessor::LINE_ALPHA») +
          scale_color_gradientn(colors=rainbow(length(unique(simplifiedDf$«SCM::particleColumn»)))) +
          ylab("Ancestor") +
          xlab("Time") +
          ylim(c(0, nParticles - 1)) +
          labs(colour='Particle') +
          facet_wrap(~timeType, scales="free_x", nrow=2, labeller=facetLabeller)
        p <- cowplot::plot_grid(p2, p1, ncol=2)
        ggsave(paste0("«outputPrefix»", "/«SCM::ancestryFileName».pdf"),
          p,
          scale=«DefaultPostProcessor::PLOT_SCALE»,
          width=«DefaultPostProcessor::PLOT_LONG_SIDE»,
          height=«DefaultPostProcessor::PLOT_SHORT_SIDE»,
          units="«DefaultPostProcessor::PLOT_UNITS»")
    ''')
  }

  def void simplePlot(File data, Object x, Object y) { simplePlot(data, x, y, "") }
  def void simplePlot(File data, Object x, Object y, String suffix) {
    if (data === null) return 
    val name = variableName(data)
    plot(data, '''
      p <- ggplot(data, aes(x = «x», y = «y»)) +
        geom_point(size = «DefaultPostProcessor::POINT_SIZE») + geom_line(alpha = «DefaultPostProcessor::LINE_ALPHA») +
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
      val geomString = if (isRealValued(types.get(TidySerializer::VALUE))) '''geom_point(size = «DefaultPostProcessor::POINT_SIZE») + geom_line(alpha = «DefaultPostProcessor::LINE_ALPHA»)''' else '''geom_step()'''
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
  
  def static densityPlot(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor) {
    return new DensityPlot(posteriorSamples, types, processor, true)
  }
  
  def static ecdfPlot(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor) {
    return new DensityPlot(posteriorSamples, types, processor, false)
  }
  
  static class DensityPlot extends GgPlot {
    val boolean density
    new(File posteriorSamples, Map<String, Class<?>> types, DefaultPostProcessor processor, boolean density) {
      super(posteriorSamples, types, processor)
      this.density = density
    }
    override ggCommand() {
      return '''
      «removeBurnIn»
      «processor.highestDensityInterval»
      hdi_df <- data %>% group_by(«facetStringName») %>%
       summarise(HDI.lower=hdi_lower(«TidySerializer::VALUE»),
                 HDI.upper=hdi_upper(«TidySerializer::VALUE»))
      
      p <- ggplot(data, aes(x = «TidySerializer::VALUE»)) +
        «IF density»geom_density«ELSE»stat_ecdf«ENDIF»() + «facetString»
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
  
  static class PathPlot extends GgPlot {
    new(File samples, Map<String, Class<?>> types, DefaultPostProcessor processor) {
      super(samples, types, processor)
    }
    override ggCommand() {
      return '''
      «removeBurnIn»
      
      p <- ggplot(data, aes(x = «TidySerializer::VALUE», colour = «Column.chain», group = «Column.chain»)) +
        geom_density() + «facetString»
        theme_bw() + 
        xlab("«variableName»") +
        ylab("density") + 
        «processor.pathPlotArguments» +
        ggtitle("Density plot for: «variableName»")
      '''
    }
    override facetVariables() {
      indices(types) => [remove(Column.chain.toString)]
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

package blang.engines.internals.factories;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.Random;
import bayonet.smc.ParticlePopulation;
import blang.engines.ParallelTempering;
import blang.engines.internals.EngineStaticUtils;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.engines.internals.Spline.MonotoneCubicSpline;
import blang.engines.internals.SplineDerivatives;
import blang.engines.internals.ptanalysis.Paths;
import blang.engines.internals.schedules.AdaptiveTemperatureSchedule;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.System;
import blang.inits.experiments.tabwriters.TabularWriter;
import blang.inits.experiments.tabwriters.TidySerializer;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.types.StaticUtils;
import briefj.BriefIO;

import static blang.engines.internals.factories.PT.MonitoringOutput.*;

import static blang.runtime.Runner.sampleColumn;

public class PT extends ParallelTempering implements PosteriorInferenceEngine  
{
  @GlobalArg public ExperimentResults results = new ExperimentResults();
  
  @Arg @DefaultValue("1_000")
  public int nScans = 1_000;
  
  @Arg(description = "Set to zero for disabling schedule adaptation")          
                 @DefaultValue("0.5")
  public double adaptFraction = 0.5;
  
  @Arg            @DefaultValue("3")
  public double nPassesPerScan = 3;
  
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  @Arg
  public Optional<Double> targetAccept = Optional.empty();
  
  // TODO: refactor InitType into interface so that this option below can be passed in this way
  @Arg  @DefaultValue({"--nParticles", "100", "--temperatureSchedule.threshold", "0.9"}) // should edit scmDefaults if defaults changed
  public SCM scmInit = scmDefault();
  
  @Arg                       @DefaultValue("SCM")
  public InitType initialization = InitType.SCM; 
  
  @Override
  public void performInference() 
  {
    List<Round> rounds = rounds(nScans, adaptFraction);
    int scanIndex = 0;
    for (Round round : rounds)
    {
      System.out.indentWithTiming("Round(" + (round.roundIndex+1) + "/" + rounds.size() + ")"); 
      reportRoundStatistics(round);
      for (int scanInRound = 0; scanInRound < round.nScans; scanInRound++)
      {
        moveKernel(nPassesPerScan);
        recordEnergyStatistics(densitySerializer, scanIndex);
        recordSamples(scanIndex);
        if (nChains() > 1)
          swapAndRecordStatistics(scanIndex);
        scanIndex++;
      }
      if (nChains() > 1) { // Note: in last round, this is done only for instrumentation purpose
        reportAcceptanceRatios(round); 
        reportParallelTemperingDiagnostics(round);
        MonotoneCubicSpline cumulativeLambdaEstimate = adapt(round.roundIndex == rounds.size() - 2);
        reportLambdaFunctions(round, cumulativeLambdaEstimate);
      }
      long roundTime = System.out.popIndent().watch.elapsed(TimeUnit.MILLISECONDS);
      reportRoundTiming(round, roundTime);
      results.flushAll();
    }
  }
  
  @SuppressWarnings("unchecked")
  private void recordEnergyStatistics(BlangTidySerializer densitySerializer, int iter)  
  {
    for (int i = 0; i < temperingParameters.size(); i++)  
    {
      densitySerializer.serialize(states[i].logDensity(), SampleOutput.allLogDensities.toString(), 
        Pair.of(sampleColumn, iter), 
        Pair.of(Column.chain, i));
      final double energy = -states[i].preAnnealedLogLikelihood();
      densitySerializer.serialize(energy, SampleOutput.energy.toString(), 
        Pair.of(sampleColumn, iter), 
        Pair.of(Column.chain, i));
    }
    densitySerializer.serialize(getTargetState().logDensity(), SampleOutput.logDensity.toString(), 
      Pair.of(sampleColumn, iter));
  }
  
  /**
   * @return The estimated cumulative lambda function. 
   */
  private MonotoneCubicSpline adapt(boolean finalAdapt)
  {
    List<Double> annealingParameters = new ArrayList<>(temperingParameters);
    Collections.reverse(annealingParameters);
    List<Double> acceptanceProbabilities = Arrays.stream(swapAcceptPrs).map(stat -> stat.getMean()).collect(Collectors.toList());
    Collections.reverse(acceptanceProbabilities);
    MonotoneCubicSpline cumulativeLambdaEstimate = EngineStaticUtils.estimateCumulativeLambda(annealingParameters, acceptanceProbabilities);
    if (targetAccept.isPresent() && finalAdapt)
    {
      List<Double> newPartition = EngineStaticUtils.targetAcceptancePartition(cumulativeLambdaEstimate, targetAccept.get());
      // here we need to take care of fact grid size may change
      nChains = Optional.of(newPartition.size());
      initialize(states[0], random);
      setAnnealingParameters(newPartition);
    }
    else
      setAnnealingParameters(EngineStaticUtils.fixedSizeOptimalPartition(cumulativeLambdaEstimate, annealingParameters.size()));
    return cumulativeLambdaEstimate;
  }
  
  private void reportAcceptanceRatios(Round round) 
  {
    TabularWriter 
      swapTabularWriter = writer(MonitoringOutput.swapStatistics),
      annealingParamTabularWriter = writer(MonitoringOutput.annealingParameters);
    
    Pair<?,?> 
      isAdapt = Pair.of(Column.isAdapt, round.isAdapt),
      r = Pair.of(Column.round, round.roundIndex);
    
    for (int i = 0; i < nChains() - 1; i++) {
      Pair<?,?> c = Pair.of(Column.chain, i);
      swapTabularWriter.write(isAdapt, r, c, 
        Pair.of(TidySerializer.VALUE, swapAcceptPrs[i].getMean()));
      annealingParamTabularWriter.write(isAdapt, r, c,
        Pair.of(TidySerializer.VALUE, temperingParameters.get(i)));
    }
  }
  
  public static int _lamdbaDiscretization = 100;
  private void reportLambdaFunctions(Round round, MonotoneCubicSpline cumulativeLambdaEstimate)
  {
    Pair<?,?> 
      r = Pair.of(Column.round, round.roundIndex),
      isAdapt = Pair.of(Column.isAdapt, round.isAdapt);
    for (int i = 1; i < _lamdbaDiscretization; i++) {
      double beta = ((double) i) / ((double) _lamdbaDiscretization);
      Pair<?,?> betaReport = Pair.of(Column.beta, beta);
      writer(MonitoringOutput.cumulativeLambda).write(
        r, isAdapt, betaReport, 
        Pair.of(TidySerializer.VALUE, cumulativeLambdaEstimate.value(beta))
      );
      writer(MonitoringOutput.lambdaInstantaneous).write(
          r, isAdapt, betaReport, 
          Pair.of(TidySerializer.VALUE, SplineDerivatives.derivative(cumulativeLambdaEstimate, beta))
        );
    }
  }
  
  private void reportRoundTiming(Round round, long time) 
  {
    writer(MonitoringOutput.roundTimings).write(
      Pair.of(Column.round, round.roundIndex),
      Pair.of(Column.isAdapt, round.isAdapt),
      Pair.of(TidySerializer.VALUE, time)
    );
    if (!round.isAdapt) {
      try {
        results.child(Runner.MONITORING_FOLDER).getAutoClosedBufferedWriter(Runner.RUNNING_TIME_SUMMARY)
          .append("postAdaptTime_ms\t" + time + "\n");
      } catch (Exception e) {}
    }
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    // TODO: may want to check forward simulators ok
    return;
  }
  
  private List<Round> rounds(int nScans, double _adaptFraction) 
  {
    double adaptFraction = nChains() == 1 ? 0.0 : _adaptFraction;
    if (adaptFraction < 0.0 || adaptFraction >= 1.0)
      throw new RuntimeException();
    List<Round> result = new ArrayList<>();
    // first split
    int remainingAdaptIters = (int) (adaptFraction * nScans);
    int nonAdapt = nScans - remainingAdaptIters;
    result.add(new Round(nonAdapt, false));
    while (remainingAdaptIters > 0)
    {
      int nextRemain = (int) (adaptFraction * remainingAdaptIters) - 1;
      result.add(new Round(remainingAdaptIters - nextRemain, true));
      remainingAdaptIters = nextRemain;
    }
    Collections.reverse(result);
    int scan = 0;
    for (int r = 0; r < result.size(); r++) 
    {
      Round cur = result.get(r);
      cur.roundIndex = r;
      cur.firstScanInclusive = scan;
      cur.lastScanExclusive = scan + cur.nScans;
      scan += cur.nScans;
    }
    return result;
  }
  
  public static enum InitType { COPIES, FORWARD, SCM }
  
  @Override
  public void setSampledModel(SampledModel model) 
  {
    // low level-init always needed
    System.out.indentWithTiming("Initialization");  
    {
      initialize(model, random);
      informedInitialization(model);
      initSerializers();
    }
    System.out.popIndent();
  }
  
  private void informedInitialization(SampledModel model) 
  {
    switch (initialization) 
    {
      case COPIES : 
        // nothing to do
        break;
      case FORWARD :
        for (SampledModel m : states)
        {
          double cParam = m.getExponent();
          m.setExponent(0.0);
          m.forwardSample(random, false);
          m.setExponent(cParam);
        }
        break;
      case SCM :
        scmInit.results = results.child("init");
        Random [] randoms = Random.parallelRandomStreams(random, scmInit.nParticles);
        ParticlePopulation<SampledModel> population = scmInit.initialize(model, randoms);
        List<Double> reorderedParameters = new ArrayList<>(temperingParameters);
        Collections.sort(reorderedParameters);
        
        for (int i = 0; i < reorderedParameters.size(); i++) 
        {
          double nextParameter = reorderedParameters.get(i);
          int chainIndex = states.length - 1 - i;
          if (nextParameter == 0.0) 
          {
            SampledModel current = states[chainIndex];
            current.forwardSample(random, false); 
          }
          else
          {
            population = scmInit.getApproximation(population, nextParameter, model, randoms, false);
            SampledModel init = population.sample(random).duplicate();
            states[chainIndex] = init;
          }
        }
        break;
      default : throw new RuntimeException();
    }
  }
  
  private BlangTidySerializer tidySerializer;
  private BlangTidySerializer densitySerializer;
  private BlangTidySerializer swapIndicatorSerializer; 
  protected void initSerializers()
  {
    tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    densitySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    swapIndicatorSerializer = new BlangTidySerializer(results.child(Runner.MONITORING_FOLDER));  
  }
  
  private void reportRoundStatistics(Round round)
  {
    int movesPerScan = (int) (nChains() /* communication */ + nPassesPerScan * states[0].nPosteriorSamplers() /* exploration */);
    System.out.formatln("Performing", round.nScans * states.length * movesPerScan, "moves...", 
      "[", 
        Pair.of("nScans", round.nScans), 
        Pair.of("nChains", states.length), 
        Pair.of("movesPerScan", movesPerScan),
      "]");
  }
  
  @SuppressWarnings("unchecked")
  private void recordSamples(int scanIndex) 
  {
    getTargetState().getSampleWriter(tidySerializer).write(
      Pair.of(sampleColumn, scanIndex));
  }
  
  @SuppressWarnings("unchecked")
  private void swapAndRecordStatistics(int scanIndex) 
  {
    // perform the swaps
    boolean[] swapIndicators = swapKernel();
    
    // record info on the swap
    for (int c = 0; c < nChains(); c++)
      swapIndicatorSerializer.serialize(swapIndicators[c] ? 1 : 0, MonitoringOutput.swapIndicators.toString(), 
        Pair.of(sampleColumn, scanIndex), 
        Pair.of(Column.chain, c));
  }
  
  private void reportParallelTemperingDiagnostics(Round round)
  {
    Pair<?,?> roundReport = Pair.of(Column.round, round.roundIndex);
    
    // swap statistics
    SummaryStatistics swapStats = StaticUtils.summaryStatistics( Arrays.stream(swapAcceptPrs).map(stat -> stat.getMean()).collect(Collectors.toList()));
    writer(MonitoringOutput.swapSummaries).printAndWrite(
      roundReport,
      Pair.of(Column.lowest, swapStats.getMin()), 
      Pair.of(Column.average, swapStats.getMean())
    );
    
    // round trip information
    results.flushAll(); // make sure first the indicators are written
    String swapIndicPath = new File(results.getFileInResultFolder(Runner.MONITORING_FOLDER), MonitoringOutput.swapIndicators + ".csv").getAbsolutePath();
    Paths paths = new Paths(swapIndicPath, round.firstScanInclusive, round.lastScanExclusive);
    
    double Lambda = Arrays.stream(swapAcceptPrs).map(stat -> 1.0 - stat.getMean()).mapToDouble(Double::doubleValue).sum();
    writer(MonitoringOutput.globalLambda).printAndWrite(
      roundReport,
      Pair.of(TidySerializer.VALUE, Lambda)
    );
    
    int n = paths.nRejuvenations();
    double tau = ((double) n / round.nScans);
    writer(MonitoringOutput.actualTemperedRestarts).printAndWrite(
      roundReport,
      Pair.of(Column.count, n), 
      Pair.of(Column.rate, tau)
    );
    
    if (reversible)
      System.err.println("Using provably suboptimal reversible PT. Do this only for PT benchmarking. Asymptotic rate is zero in this regime.");
    else
    {
      double tauBar = 1.0 / (2.0 + 2.0 * Lambda);
      double nBar = tauBar * round.nScans;
      writer(asymptoticRoundTripBound).printAndWrite(
        roundReport,
        Pair.of(Column.count, nBar), 
        Pair.of(Column.rate, tauBar)
      );
    }
    
    Optional<Double> optionalLogNorm = thermodynamicEstimator();
    if (optionalLogNorm.isPresent())
      writer(MonitoringOutput.logNormalizationContantProgress).printAndWrite(
        roundReport,
        Pair.of(TidySerializer.VALUE, optionalLogNorm.get())
      );
    else
      System.out.println("Thermodynamic integration disabled as support is being annealed\n"
                       + "  Use \"--engine SCM\" for log normalization computation instead");
    
    // log normalization, again (this gets overwritten, so this will be the final estimate in the same format as SCM)
    if (optionalLogNorm.isPresent())
      BriefIO.write(results.getFileInResultFolder(Runner.LOG_NORM_ESTIMATE), "" + optionalLogNorm.get());
  }
  
  private SCM scmDefault() {
    SCM scmDefault = new SCM();
    scmDefault.nParticles = 100;
    AdaptiveTemperatureSchedule schedule = new AdaptiveTemperatureSchedule();
    schedule.threshold = 0.9;
    scmDefault.temperatureSchedule = schedule;
    return scmDefault;
  }
  
  private TabularWriter writer(MonitoringOutput output)
  {
    return results.child(Runner.MONITORING_FOLDER).getTabularWriter(output.toString());
  }
  
  public static enum MonitoringOutput
  {
    swapIndicators, swapStatistics, annealingParameters, swapSummaries, logNormalizationContantProgress, 
    globalLambda, actualTemperedRestarts, asymptoticRoundTripBound, roundTimings, lambdaInstantaneous, cumulativeLambda
  }
  
  public static enum SampleOutput
  {
    energy, logDensity, allLogDensities;
  }
  
  public static enum Column
  {
    chain, round, isAdapt, count, rate, lowest, average, beta
  }
  
  private static class Round
  {
    int nScans;
    int roundIndex = -1;
    int firstScanInclusive;
    int lastScanExclusive;
    boolean isAdapt;
    public Round(int nScans, boolean isAdapt) {
      this.nScans = nScans;
      this.isAdapt = isAdapt;
    }
    @Override
    public String toString() {
      return "Round [nScans=" + nScans + ", roundIndex=" + roundIndex + ", isAdapt=" + isAdapt + "]";
    }
  }
}

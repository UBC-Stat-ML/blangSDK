package blang.engines.internals.factories;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.Random;
import bayonet.smc.ParticlePopulation;
import blang.engines.ParallelTempering;
import blang.engines.internals.EngineStaticUtils;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.engines.internals.schedules.AdaptiveTemperatureSchedule;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.System;
import blang.inits.experiments.tabwriters.TabularWriter;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefIO;

import static blang.runtime.Runner.sampleColumn;

public class PT extends ParallelTempering implements PosteriorInferenceEngine  
{
  @GlobalArg public ExperimentResults results = new ExperimentResults();
  
  @Arg @DefaultValue("1_000")
  public int nScans = 1_000;
  
  @Arg           @DefaultValue("0.5")
  public double adaptFraction = 0.5;
  
  @Arg         @DefaultValue("3")
  public double nPassesPerScan = 3;
  
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  @Arg
  public Optional<Double> targetAccept = Optional.empty();
  
  @Arg  @DefaultValue({"--nParticles", "100", "--temperatureSchedule.threshold", "0.9"}) // need to edit below if modified!
  public SCM scmInit = scmDefault();
  private SCM scmDefault() {
    SCM scmDefault = new SCM();
    scmDefault.nParticles = 100;
    AdaptiveTemperatureSchedule schedule = new AdaptiveTemperatureSchedule();
    schedule.threshold = 0.9;
    scmDefault.temperatureSchedule = schedule;
    return scmDefault;
  }
  
  @Arg                       @DefaultValue("SCM")
  public InitType initialization = InitType.SCM;
  
  public static enum InitType { COPIES, FORWARD, SCM }
  
  @Override
  public void setSampledModel(SampledModel model) 
  {
    // low level-init always needed
    System.out.indentWithTiming("Initialization");  
    {
      initialize(model, random);
      informedInitialization(model);
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
        for (int i = 1; i < reorderedParameters.size(); i++) 
        {
          double nextParameter = reorderedParameters.get(i);
          population = scmInit.getApproximation(population, nextParameter, model, randoms, false);
          SampledModel init = population.sample(random).duplicate();
          states[states.length - 1 - i] = init;
        }
        break;
      default : throw new RuntimeException();
    }
  }
  
  public static final String
  
    energyFileName = "energy",
    logDensityFileName = "logDensity",
    allLogDensitiesFileName = "allLogDensities",
    swapIndicatorsFileName = "swapIndicators",
    swapStatisticsFileName = "swapStatistics",
    
    chainColumn = "chain",
    acceptPrColumn = "acceptPr",
    annealingParameterColumn = "annealingParameter";
  
  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    BlangTidySerializer densitySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    BlangTidySerializer swapIndicatorSerializer = new BlangTidySerializer(results.child(Runner.MONITORING_FOLDER));  
    int iter = 0;
    List<Round> rounds = rounds(nScans, adaptFraction);
    for (Round round : rounds)
    {
      System.out.indentWithTiming("Round(" + (round.roundIndex+1) + "/" + rounds.size() + ")"); 
      int movesPerScan = (int) (1 /* communication */ + nPassesPerScan * states[0].nPosteriorSamplers() /* exploration */);
      System.out.formatln("Performing", round.nScans * states.length * movesPerScan, "moves...", 
        "[", 
          Pair.of("nScans", round.nScans), 
          Pair.of("nChains", states.length), 
          Pair.of("movesPerScan", movesPerScan),
        "]");
      for (int iterInRound = 0; iterInRound < round.nScans; iterInRound++)
      {
        moveKernel(nPassesPerScan);
        
        reportEnergyStatistics(densitySerializer, iter);
        
        // state statistics
        getTargetState().getSampleWriter(tidySerializer).write(
            Pair.of(sampleColumn, iter));
        
        // perform the swaps
        boolean[] swapIndicators = swapKernel();
        
        // record info on the swap
        for (int c = 0; c < nChains(); c++)
          swapIndicatorSerializer.serialize(swapIndicators[c] ? 1 : 0, swapIndicatorsFileName, 
              Pair.of(sampleColumn, iter), 
              Pair.of(chainColumn, c));
        
        iter++;
      }
      
      if (nChains() > 1)
      {
        System.out.println("Lowest swap pr: " + Arrays.stream(swapAcceptPrs).mapToDouble(stat -> stat.getMean()).min().getAsDouble());
        double logNormEstimate = thermodynamicEstimator();
        System.out.println("Log normalization constant estimate: " + logNormEstimate);
        BriefIO.write(results.getFileInResultFolder(Runner.LOG_NORM_ESTIMATE), "" + logNormEstimate);
      }
        
      reportAcceptanceRatios(round); 
      
      if (round.isAdapt) 
        adapt(round.roundIndex == rounds.size() - 2);
      
      results.flushAll();
      System.out.popIndent();
    }
  }
  
  @SuppressWarnings("unchecked")
  private void reportEnergyStatistics(BlangTidySerializer densitySerializer, int iter)  
  {
    for (int i = 0; i < temperingParameters.size(); i++)  
    {
      densitySerializer.serialize(states[i].logDensity(), allLogDensitiesFileName, 
          Pair.of(sampleColumn, iter), 
          Pair.of(chainColumn, i));
      final double energy = -states[i].preAnnealedLogLikelihood();
      densitySerializer.serialize(energy, energyFileName, 
          Pair.of(sampleColumn, iter), 
          Pair.of(chainColumn, i));
    }
    densitySerializer.serialize(getTargetState().logDensity(), logDensityFileName, 
        Pair.of(sampleColumn, iter));
  }
  
  private void adapt(boolean finalAdapt)
  {
    List<Double> annealingParameters = new ArrayList<>(temperingParameters);
    Collections.reverse(annealingParameters);
    List<Double> acceptanceProbabilities = Arrays.stream(swapAcceptPrs).map(stat -> stat.getMean()).collect(Collectors.toList());
    Collections.reverse(acceptanceProbabilities);
    if (targetAccept.isPresent() && finalAdapt)
    {
      List<Double> newPartition = EngineStaticUtils.targetAcceptancePartition(annealingParameters, acceptanceProbabilities, targetAccept.get());
      // here we need to take care of fact grid size may change
      nChains = Optional.of(newPartition.size());
      initialize(states[0], random);
      setAnnealingParameters(newPartition);
    }
    else
      setAnnealingParameters(EngineStaticUtils.fixedSizeOptimalPartition(annealingParameters, acceptanceProbabilities, annealingParameters.size()));
  }
  
  private void reportAcceptanceRatios(Round round) 
  {
    TabularWriter tabularWriter = results.child(Runner.MONITORING_FOLDER).getTabularWriter(swapStatisticsFileName);
    if (round != null) 
    {
      tabularWriter = tabularWriter
          .child("isAdapt", round.isAdapt)
          .child("round", round.roundIndex);
    }
    for (int i = 0; i < nChains() - 1; i++)
      tabularWriter.write(
          Pair.of(chainColumn, i), 
          Pair.of(annealingParameterColumn, temperingParameters.get(i)), 
          Pair.of(acceptPrColumn, swapAcceptPrs[i].getMean()));
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
    for (int r = 0; r < result.size(); r++) 
      result.get(r).roundIndex = r;
    return result;
  }
  
  private static class Round
  {
    int nScans;
    int roundIndex = -1;
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

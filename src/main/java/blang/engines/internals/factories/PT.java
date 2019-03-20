package blang.engines.internals.factories;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import org.eclipse.xtext.xbase.lib.Pair;

import com.google.common.base.Stopwatch;

import bayonet.distributions.Random;
import blang.engines.ParallelTempering;
import blang.engines.internals.EngineStaticUtils;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.inits.experiments.tabwriters.TabularWriter;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

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
  
  @Override
  public void setSampledModel(SampledModel model) 
  {
    initialize(model, random);
  }
  
  public static final String
  
    energyFileName = "energy",
    logDensityFileName = "logDensity",
    allLogDensitiesFileName = "allLogDensities",
    swapIndicatorsFileName = "swapIndicators",
    swapStatisticsFileName = "swapStatistics",
    adaptSwapStatisticsFileName = "adaptSwapStatistics",
    
    sampleColumn = "sample",
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
      System.out.println("Starting round " + (round.roundIndex+1) + "/" + rounds.size() + " [" + round.nScans + " scans x " + states.length +  " chains x " + (int) (1 /* communication */ + nPassesPerScan * states[0].nPosteriorSamplers() /* exploration */) + " moves/scan]");
      Stopwatch watch = Stopwatch.createStarted();
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
              Pair.of(chainColumn, c),
              Pair.of(annealingParameterColumn, temperingParameters.get(c)));
        
        iter++;
      }
      if (nChains() > 1)
        System.out.println("\tLowest swap pr: " + Arrays.stream(swapAcceptPrs).mapToDouble(stat -> stat.getMean()).min().getAsDouble());
      System.out.println("\tRound completed in " + watch);
      
      if (!round.isAdapt) // report final swap stats
        reportAcceptanceRatios();
      
      reportAcceptanceRatios(round); // report also more thorough swap stat
      
      if (round.isAdapt) 
        adapt(round.roundIndex == rounds.size() - 2);
        
    }
  }
  
  @SuppressWarnings("unchecked")
  private void reportEnergyStatistics(BlangTidySerializer densitySerializer, int iter)  
  {
    for (int i = 0; i < temperingParameters.size(); i++)  
    {
      final Double temperingParam =  temperingParameters.get(i);
      densitySerializer.serialize(states[i].logDensity(), allLogDensitiesFileName, 
          Pair.of(sampleColumn, iter), 
          Pair.of(chainColumn, i),
          Pair.of(annealingParameterColumn, temperingParam));
      final double energy = -states[i].preAnnealedLogLikelihood();
      densitySerializer.serialize(energy, energyFileName, 
          Pair.of(sampleColumn, iter), 
          Pair.of(chainColumn, i),
          Pair.of(annealingParameterColumn, temperingParam));
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

  private void reportAcceptanceRatios()
  {
    reportAcceptanceRatios(null);
  }
  
  private void reportAcceptanceRatios(Round round) 
  {
    TabularWriter tabularWriter = results.child(Runner.MONITORING_FOLDER).getTabularWriter(round == null ? swapStatisticsFileName : adaptSwapStatisticsFileName);
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

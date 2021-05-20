package blang.engines;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;

import bayonet.distributions.Random;
import bayonet.math.NumericalUtils;
import blang.engines.internals.LogSumAccumulator;
import blang.engines.internals.ladders.EquallySpaced;
import blang.engines.internals.ladders.TemperatureLadder;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.Cores;
import blang.runtime.SampledModel;
import blang.types.StaticUtils;
import briefj.BriefParallel;

public class ParallelTempering
{
  @Arg           @DefaultValue("Dynamic")
  public Cores nThreads = Cores.dynamic();  
  
  @Arg(description = "The annealing schedule to use or if adaptation is used, the initial value")                   
                         @DefaultValue("EquallySpaced")
  public TemperatureLadder ladder = new EquallySpaced();
  
  @Arg
        @DefaultValue("8")
  public int nChains = 8;
  
  @Arg              @DefaultValue("true")
  public boolean usePriorSamples = true;
  
  @Arg         @DefaultValue("false")
  public boolean reversible = false;
  
  // convention: state index 0 is room temperature (target of interest)
  public SampledModel [] states;
  public List<Double> temperingParameters;
  protected Random [] parallelRandomStreams;
  public SummaryStatistics [] energies, swapAcceptPrs;
  protected ArrayList<ArrayList<Double>> logNumeratorRatios;   // Both ratios used by bridge sampling estimator
  protected ArrayList<ArrayList<Double>> logDenominatorRatios; // Dimensions: (nChains, nScans)
  protected LogSumAccumulator [] logSumLikelihoodRatios; // used by Stepping stone marginalization
  protected int swapIndex = 0;
  protected boolean [] swapIndicators;
   
  public SampledModel getTargetState()
  {
    if (states[0].getExponent() != 1.0)
      throw new RuntimeException();
    return states[0];
  }
  
  public boolean[] swapKernel() 
  {
    return swapKernel(reversible);
  }
  
  public boolean[] swapKernel(boolean reversible)
  {
    swapIndicators = new boolean[nChains()];
    int offset = reversible ? parallelRandomStreams[0].nextInt(2) : swapIndex++ % 2; 
    BriefParallel.process((nChains() - offset) / 2, nThreads.numberAvailable(), swapIndex ->
    {
      int chainIndex = offset + 2 * swapIndex;
      double acceptPr = swapKernel(parallelRandomStreams[chainIndex], chainIndex);
      swapAcceptPrs[chainIndex].addValue(acceptPr);
    });
    return swapIndicators;
  }
  
  public void moveKernel(double nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.numberAvailable(), chainIndex -> 
    {
      Random random = parallelRandomStreams[chainIndex];
      SampledModel current = states[chainIndex];
      if (temperingParameters.get(chainIndex) == 0 && usePriorSamples)
        current.forwardSample(random, false);
      else
        current.posteriorSamplingScan(random, nPasses); 
      energies[chainIndex].addValue(-current.preAnnealedLogLikelihood());
    });
  }
  
  /**
   * @param random
   * @param i one of the indices to swap, the other being i+1
   * @return Accept pr
   */
  public double swapKernel(Random random, int i)
  {
    final double acceptPr = swapAcceptPr(i);
    if (random.nextBernoulli(acceptPr))
      doSwap(i);
    return acceptPr;
  }
  
  public double swapAcceptPr(int i) 
  {
    int j = i + 1;
    final double steppingStoneLogRatio = // recall: tempering parameter j is closer to prior
        + states[j].logDensity(temperingParameters.get(i))   
        - states[j].logDensity(temperingParameters.get(j)); // so for stepping stone we want the proposal to be the one closer to prior (this is IS so we want proposal to be wider)
    
    logSumLikelihoodRatios[i].add(steppingStoneLogRatio); 
    
      
    final double logDensityRatio =
        + states[i].logDensity(temperingParameters.get(j))
        - states[i].logDensity(temperingParameters.get(i));
    final double logRatio = steppingStoneLogRatio + logDensityRatio;

    logNumeratorRatios.get(i).add(steppingStoneLogRatio);
    logDenominatorRatios.get(i).add(-logDensityRatio);
        
    double acceptPr = Math.min(1.0, Math.exp(logRatio));
    if (Double.isNaN(acceptPr))
      acceptPr = 0.0; // should only happen right at the beginning
    return acceptPr;
  }
  
  /**
   * @return the estimate of log probability or empty if the conditions for thermodynamic integration 
   *   are not met (i.e. support is being annealed).
   */
  public Optional<Double> thermodynamicEstimator() 
  {
    for (int c = 0; c < nChains(); c++)
      if (states[c].annealedOutOfSupportDetected() || states[c].nOtherAnnealedFactors() > 0)
        return Optional.empty();
    
    double sum = 0.0;
    for (int c = 0; c < nChains() - 1; c++) {
      sum += (temperingParameters.get(c) - temperingParameters.get(c+1)) * (energies[c].getMean() + energies[c+1].getMean())/ 2.0;
    }
    return Optional.of(-sum);
  }
  
  public Optional<Double> bridgeSamplingEstimator() 
  {
    double threshold = 1e-7;     // Stopping criterion
    int iterationThreshold = 30; // Stopping criterion
    double [] logNormConstRatioEstimates = new double[nChains() - 1]; // estimates of Z{i} / Z{i+1}; i is closer to posterior than (i + 1)
    for (int c = 0; c < nChains() - 1; c++) // arbitrary initial estimates
      logNormConstRatioEstimates[c] = 1;

    int iterationCount = 1;
    double difference = threshold + 1;
    double estimate = 0;

    while (difference >= threshold) {
      for (int c = 0; c < nChains() - 1; c++)
        logNormConstRatioEstimates[c] = estimateRatio(c, logNormConstRatioEstimates[c]);
      double newEstimate = 0;
      for (double logRatioEstimate : logNormConstRatioEstimates)
        newEstimate += logRatioEstimate;
      difference = Math.abs(newEstimate - estimate);
      estimate = newEstimate;
      if (iterationCount >= iterationThreshold)
        break;
      iterationCount++;
    }
    
    return Optional.of(estimate);
  }

  private double estimateRatio(int c, double logRatioEstimate) {
    LogSumAccumulator numerator = new LogSumAccumulator();
    for (int i = 0; i < logNumeratorRatios.get(c).size(); i++) {
      numerator.add(logNumeratorRatios.get(c).get(i) - NumericalUtils.logAdd(logNumeratorRatios.get(c).get(i), logRatioEstimate));
    }

    LogSumAccumulator denominator = new LogSumAccumulator();
    for (int i = 0; i < logDenominatorRatios.get(c).size(); i++) {
      denominator.add(-NumericalUtils.logAdd(logDenominatorRatios.get(c).get(i), logRatioEstimate));
    }
    
    return numerator.logSum() - denominator.logSum() ;
  }

  public Optional<Double> steppingStoneEstimator() 
  {
    if (nChains() == 1) return Optional.empty();
    
    double result = 0.0;
    for (int c = 0; c < nChains() - 1; c++) {
      LogSumAccumulator accumulator = logSumLikelihoodRatios[c];
      result += accumulator.logSum() - Math.log(accumulator.numberOfTerms());
    }
    return Optional.of(result);
  }
  
  private void doSwap(int i) 
  {
    int j = i + 1;
    SampledModel tmp = states[i];
    states[i] = states[j];
    states[j] = tmp;
    states[i].setExponent(temperingParameters.get(i));
    states[j].setExponent(temperingParameters.get(j));
    swapIndicators[i] = true;
  }
  
  public int nChains()
  {
    return states.length;
  }
  
  public void initialize(SampledModel prototype, Random random)
  {
    if (nChains < 1)
      throw new RuntimeException("Number of tempering chains must be greater than zero.");
    temperingParameters = ladder.temperingParameters(nChains);
    if (nChains != temperingParameters.size())
      throw new RuntimeException();
    states = initStates(prototype, nChains);
    setAnnealingParameters(temperingParameters);
    parallelRandomStreams =  Random.parallelRandomStreams(random, nChains);
  }
  
  public void setAnnealingParameters(List<Double> parameters) 
  {
    int nChains = parameters.size();
    if (nChains != states.length)
      throw new RuntimeException();
    
    temperingParameters = new ArrayList<Double>(parameters);
    Collections.sort(temperingParameters, Comparator.reverseOrder());
    if (temperingParameters.get(0) != 1.0)
      throw new RuntimeException();
    
    for (int i = 0; i < nChains; i++)
      states[i].setExponent(temperingParameters.get(i)); 
    
    swapAcceptPrs = initStats(nChains - 1);
    energies = initStats(nChains);
    logSumLikelihoodRatios = new LogSumAccumulator[nChains - 1];
    logNumeratorRatios = new ArrayList<ArrayList<Double>>();
    logDenominatorRatios = new ArrayList<ArrayList<Double>>();
    for (int i = 0; i < nChains - 1; i++) {
      logSumLikelihoodRatios[i] = new LogSumAccumulator(); 
      logNumeratorRatios.add(new ArrayList<Double>()); 
      logDenominatorRatios.add(new ArrayList<Double>());
    }
  }
  
  private SampledModel [] initStates(SampledModel prototype, int nChains)
  {
    SampledModel [] result = (SampledModel []) new SampledModel[nChains];
    if (nChains == 1)
      result[0] = prototype;
    else
      for (int i = 0; i < nChains; i++)
        result[i] = prototype.duplicate();
    return result;
  }
  
  
  public static SummaryStatistics[] initStats(int size)
  {
    SummaryStatistics[] result = new SummaryStatistics[size];
    for (int i = 0; i < size; i++)
      result[i] = StaticUtils.summaryStatistics();
    return result;
  }
}

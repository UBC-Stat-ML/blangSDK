package blang.engines;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;

import bayonet.distributions.Random;
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
  
  @Arg(description = "If unspecified, use 8.") 
                                  @DefaultValue("8")
  public Optional<Integer> nChains = Optional.of(8);
  
  @Arg              @DefaultValue("true")
  public boolean usePriorSamples = true;
  
  @Arg         @DefaultValue("false")
  public boolean reversible = false;
  
  // convention: state index 0 is room temperature (target of interest)
  protected SampledModel [] states;
  protected List<Double> temperingParameters;
  protected Random [] parallelRandomStreams;
  protected SummaryStatistics [] energies, swapAcceptPrs;
  private int swapIndex = 0;
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
    int j = i + 1;
    double logRatio = 
        states[i].logDensity(temperingParameters.get(j)) + states[j].logDensity(temperingParameters.get(i))
      - states[i].logDensity(temperingParameters.get(i)) - states[j].logDensity(temperingParameters.get(j));
    double acceptPr = Math.min(1.0, Math.exp(logRatio));
    if (Double.isNaN(acceptPr))
      acceptPr = 0.0; // should only happen right at the beginning
    if (random.nextBernoulli(acceptPr))
    {
      swapIndicators[i] = true;
      doSwap(i);
    }
    return acceptPr;
  }
  
  /**
   * @return the estimate of log probability or empty if the conditions for thermodynamic integration 
   *   are not met (i.e. support is being annealed).
   */
  public Optional<Double> thermodynamicEstimator() 
  {
    for (int c = 0; c < nChains(); c++)
      if (states[c].outOfSupportDetected())
        return Optional.empty();
    
    double sum = 0.0;
    for (int c = 0; c < nChains() - 1; c++) {
      sum += (temperingParameters.get(c) - temperingParameters.get(c+1)) * (energies[c].getMean() + energies[c+1].getMean())/ 2.0;
    }
    return Optional.of(-sum);
  }
  
  private void doSwap(int i) 
  {
    int j = i + 1;
    SampledModel tmp = states[i];
    states[i] = states[j];
    states[j] = tmp;
    states[i].setExponent(temperingParameters.get(i));
    states[j].setExponent(temperingParameters.get(j));
  }
  
  public int nChains()
  {
    return states.length;
  }
  
  public void initialize(SampledModel prototype, Random random)
  {
    if (nChains.isPresent() && nChains.get() < 1)
      throw new RuntimeException("Number of tempering chains must be greater than zero.");
    temperingParameters = ladder.temperingParameters(nChains.orElse(nThreads.numberAvailable()));
    int nChains = temperingParameters.size();
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
  
  
  private static SummaryStatistics[] initStats(int size)
  {
    SummaryStatistics[] result = new SummaryStatistics[size];
    for (int i = 0; i < size; i++)
      result[i] = StaticUtils.summaryStatistics(0.0);
    return result;
  }
}

package blang.engines;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;

import bayonet.distributions.Random;
import blang.engines.internals.ladders.Geometric;
import blang.engines.internals.ladders.TemperatureLadder;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.Cores;
import blang.runtime.SampledModel;
import briefj.BriefParallel;

public class ParallelTempering
{
  @Arg   
  public Cores nThreads = Cores.maxAvailable();  
  
  @Arg                   @DefaultValue("Geometric")
  public TemperatureLadder ladder = new Geometric();
  
  @Arg(description = "If unspecified, use the number of threads.")
  public Optional<Integer> nChains = Optional.empty();
  
  // convention: state index 0 is room temperature (target of interest)
  private SampledModel [] states;
  private List<Double> temperingParameters;
  private Random [] parallelRandomStreams;
  protected SummaryStatistics [] swapAcceptPrs;
  
  public SampledModel getTargetState()
  {
    return states[0];
  }
  
  public int nChains()
  {
    return states.length;
  }
  
  public void initialize(SampledModel prototype, Random random)
  {
    temperingParameters = new ArrayList<>();
    List<SampledModel> initStates = new ArrayList<>();
    ladder.temperingParameters(temperingParameters, initStates, nChains.orElse(nThreads.available));
    System.out.println("Temperatures: " + temperingParameters);
    int nChains = temperingParameters.size();
    states = initStates.isEmpty() ? defaultInit(prototype, nChains, random) : (SampledModel[]) initStates.toArray();
    swapAcceptPrs = new SummaryStatistics[nChains - 1];
    for (int i = 0; i < nChains - 1; i++)
      swapAcceptPrs[i] = new SummaryStatistics();
    parallelRandomStreams =  Random.parallelRandomStreams(random, nChains);
  }
  
  private static SampledModel [] defaultInit(SampledModel prototype, int nChains, Random random)
  {
    SampledModel [] result = (SampledModel []) new SampledModel[nChains];
    for (int i = 0; i < nChains; i++)
      result[i] = prototype.duplicate();
    return result;
  }
  
  private int iterationIndex = 0;
  public void swapKernel()
  {
    int offset = iterationIndex++ % 2;
    BriefParallel.process((nChains() - offset) / 2, nThreads.available, swapIndex ->
    {
      int chainIndex = offset + 2 * swapIndex;
      boolean accepted = swapKernel(parallelRandomStreams[chainIndex], chainIndex);
      swapAcceptPrs[chainIndex].addValue(accepted ? 1.0 : 0.0);
    });
  }
  
  public void moveKernel(int nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.available, chainIndex -> 
    {
      Random random = parallelRandomStreams[chainIndex];
      SampledModel current = states[chainIndex];
      if (chainIndex == 0)
        sampleFromPrior(random, current);
      else
        for (int i = 0; i < nPasses; i++)
          sampleMove(random, current, temperingParameters.get(chainIndex));
    });
  }
  
  private void sampleFromPrior(Random random, SampledModel model) 
  {
    model.setExponent(0.0);
    model.forwardSample(random, false);
  }

  private void sampleMove(Random random, SampledModel model, double temperature)
  {
    model.setExponent(temperature);
    model.posteriorSamplingStep_deterministicScanAndShuffle(random); 
  }
  
  /**
   * 
   * @param random
   * @param i
   * @return If accepted.
   */
  public boolean swapKernel(Random random, int i)
  {
    int j = i + 1;
    double logRatio = 
        states[i].logDensity(temperingParameters.get(j)) + states[j].logDensity(temperingParameters.get(i))
      - states[i].logDensity(temperingParameters.get(i)) + states[j].logDensity(temperingParameters.get(j));
    if (random.nextBernoulli(Math.min(1.0, Math.exp(logRatio))))
    {
      doSwap(i);
      return true;
    }
    else
      return false;
  }
  
  private void doSwap(int i) 
  {
    int j = i + 1;
    SampledModel tmp = states[i];
    states[i] = states[j];
    states[j] = tmp;
  }
}

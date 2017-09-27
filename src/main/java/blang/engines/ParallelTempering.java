package blang.engines;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;

import bayonet.distributions.Random;
import blang.engines.internals.AnnealingKernels;
import blang.engines.internals.TemperedParticle;
import blang.engines.internals.ladders.Geometric;
import blang.engines.internals.ladders.TemperatureLadder;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.Cores;
import briefj.BriefParallel;

public class ParallelTempering<P extends TemperedParticle> 
{
  @Arg   
  public Cores nThreads = Cores.maxAvailable();  
  
  @Arg                      @DefaultValue("Geometric")
  public TemperatureLadder<P> ladder = new Geometric<P>();
  
  AnnealingKernels<P> invariantKernels, exactBaseKernel;
  
  // convention: state index 0 is room temperature (target of interest)
  private P [] states;
  private List<Double> temperingParameters;
  private Random [] parallelRandomStreams;
  protected SummaryStatistics [] swapAcceptPrs;
  
  public P getTargetState()
  {
    return states[0];
  }
  
  public int nChains()
  {
    return states.length;
  }
  
  @SuppressWarnings("unchecked")
  public void initialize(AnnealingKernels<P> invariantKernels, AnnealingKernels<P> exactBaseKernel, Random random)
  {
    this.exactBaseKernel = exactBaseKernel;
    this.invariantKernels = invariantKernels;
    temperingParameters = new ArrayList<>();
    List<P> initStates = new ArrayList<>();
    ladder.temperingParameters(invariantKernels, temperingParameters, initStates, nThreads.available);
    System.out.println("Temperatures: " + temperingParameters);
    int nChains = temperingParameters.size();
    states = initStates.isEmpty() ? defaultInit(invariantKernels, exactBaseKernel, nChains, random) : (P[]) initStates.toArray();
    swapAcceptPrs = new SummaryStatistics[nChains - 1];
    for (int i = 0; i < nChains - 1; i++)
      swapAcceptPrs[i] = new SummaryStatistics();
    parallelRandomStreams =  Random.parallelRandomStreams(random, nChains);
  }
  
  private static <P> P [] defaultInit(AnnealingKernels<P> invariantKernels, AnnealingKernels<P> exactBaseKernel, int nChains, Random random)
  {
    P oneCopy = (exactBaseKernel == null ? invariantKernels : exactBaseKernel).sampleNext(random, null, 0.0);
    @SuppressWarnings({ "unchecked" })
    P [] result = (P []) new TemperedParticle[nChains];
    for (int i = 0; i < nChains; i++)
      result[i] = invariantKernels.deepCopy(oneCopy);
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
    if (invariantKernels.inPlace())
      moveKernelInPlace(nPasses);
    else
      moveKernelAndAssign(nPasses);
  }
  
  private void moveKernelInPlace(int nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.available, chainIndex -> 
    {
      if (usePriorOnlyChain(chainIndex))
        exactBaseKernel.sampleNext(parallelRandomStreams[chainIndex], states[chainIndex], temperingParameters.get(chainIndex));
      else
        for (int i = 0; i < nPasses; i++)
          invariantKernels.sampleNext(parallelRandomStreams[chainIndex], states[chainIndex], temperingParameters.get(chainIndex));
    });
  }
  
  private boolean usePriorOnlyChain(int index)
  {
    if (exactBaseKernel == null)
      return false;
    if (nChains() == 1)
      return false;
    return index == nChains() - 1;
  }
  
  private void moveKernelAndAssign(int nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.available, chainIndex -> 
    {
      for (int i = 0; i < nPasses; i++)
        states[chainIndex] = invariantKernels.sampleNext(parallelRandomStreams[chainIndex], states[chainIndex], temperingParameters.get(chainIndex));
    });
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
    P tmp = states[i];
    states[i] = states[j];
    states[j] = tmp;
  }
}

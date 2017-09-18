package blang.algo;

import java.util.ArrayList;
import java.util.List;

import bayonet.distributions.Random;
import blang.algo.ladders.Geometric;
import blang.algo.ladders.TemperatureLadder;
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
  
  AnnealingKernels<P> kernels; 
  
  // convention: state index 0 is room temperature (target of interest)
  private P [] states;
  private List<Double> temperingParameters;
  private Random [] parallelRandomStreams;
  
  public P getTargetState()
  {
    return states[0];
  }
  
  public int nChains()
  {
    return states.length;
  }
  
  @SuppressWarnings("unchecked")
  public void initialize(AnnealingKernels<P> kernels)
  {
    this.kernels = kernels;
    temperingParameters = new ArrayList<>();
    List<P> initStates = new ArrayList<>();
    ladder.temperingParameters(kernels, temperingParameters, initStates, nThreads.available);
    int nChains = temperingParameters.size();
    states = initStates.isEmpty() ? defaultInit(kernels, nChains) : (P[]) initStates.toArray();
  }
  
  private static <P> P [] defaultInit(AnnealingKernels<P> kernels, int nChains)
  {
    P oneCopy = kernels.sampleInitial(new Random(1));
    @SuppressWarnings({ "unchecked" })
    P [] result = (P []) new TemperedParticle[nChains];
    for (int i = 0; i < nChains; i++)
      result[i] = kernels.deepCopy(oneCopy);
    return result;
  }
  
  private int iterationIndex = 0;
  public void swapKernel(Random random)
  {
    int offset = iterationIndex % 2;
    BriefParallel.process((nChains() - offset) / 2, nThreads.available, swapIndex ->
    {
      int chainIndex = offset + 2 * swapIndex;
      swapKernel(parallelRandomStreams[chainIndex], chainIndex);
    });
  }
  
  public void moveKernel(Random random, int nPasses)
  {
    if (kernels.inPlace())
      moveKernelInPlace(random, nPasses);
    else
      moveKernelAndAssign(random, nPasses);
  }
  
  private void moveKernelInPlace(Random random, int nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.available, chainIndex -> 
    {
      for (int i = 0; i < nPasses; i++)
        kernels.sampleNext(random, states[chainIndex], temperingParameters.get(chainIndex));
    });
  }
  
  private void moveKernelAndAssign(Random random, int nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.available, chainIndex -> 
    {
      for (int i = 0; i < nPasses; i++)
        states[chainIndex] = kernels.sampleNext(random, states[chainIndex], temperingParameters.get(chainIndex));
    });
  }
  
  public static void main(String [] args)
  {
    int nc = Runtime.getRuntime().availableProcessors();
    System.out.println(nc);
  }
  
  public void swapKernel(Random random, int i)
  {
    int j = i + 1;
    double logRatio = 
        states[i].logDensity(temperingParameters.get(j)) + states[j].logDensity(temperingParameters.get(i))
      - states[i].logDensity(temperingParameters.get(i)) + states[j].logDensity(temperingParameters.get(j));
    if (random.nextBernoulli(Math.min(1.0, Math.log(logRatio))))
      doSwap(i);
  }
  
  private void doSwap(int i) 
  {
    int j = i + 1;
    P tmp = states[i];
    states[i] = states[j];
    states[j] = tmp;
  }
}

package blang.engines;

import java.util.ArrayList;
import java.util.Arrays;
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
import briefj.BriefParallel;

public class ParallelTempering
{
  @Arg           @DefaultValue("Dynamic")
  public Cores nThreads = Cores.dynamic();  
  
  @Arg                   @DefaultValue("EquallySpaced")
  public TemperatureLadder ladder = new EquallySpaced();
  
  @Arg(description = "If unspecified, use the number of threads.") 
                                  @DefaultValue("8")
  public Optional<Integer> nChains = Optional.of(8);
  
  @Arg              @DefaultValue("true")
  public boolean usePriorSamples = true;
  
  @Arg @DefaultValue("1")
  public int nParticlesPerTemperature = 1;
  
  // convention: state index 0 is room temperature (target of interest)
  protected SampledModel [][] states;
  protected List<Double> temperingParameters;
  private Random [] parallelRandomStreams;
  protected SummaryStatistics [] swapAcceptPrs;
  private int iterationIndex = 0;
  
  public SampledModel[] getTargetStates()
  {
    if (states[0][0].getExponent() != 1.0)
      throw new RuntimeException();
    return states[0];
  }
  
  public void swapKernel()
  {
    int offset = iterationIndex++ % 2;
    BriefParallel.process((nChains() - offset) / 2, nThreads.numberAvailable(), swapIndex ->
    {
      int chainIndex = offset + 2 * swapIndex;
      double acceptPr = swapKernel(parallelRandomStreams[chainIndex], chainIndex);
      swapAcceptPrs[chainIndex].addValue(acceptPr);
    });
  }
  
  public void moveKernel(int nPasses) 
  {
    BriefParallel.process(nChains(), nThreads.numberAvailable(), chainIndex -> 
    {
      Random random = parallelRandomStreams[chainIndex];
      for (SampledModel current : states[chainIndex])
        if (temperingParameters.get(chainIndex) == 0 && usePriorSamples)
          current.forwardSample(random, false);
        else
          for (int i = 0; i < nPasses; i++)
            current.posteriorSamplingScan(random); 
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
    
//    {
//      System.out.println("---");
//      
//      // sort in place the two temperature by their respective annealed logDensities
////      Arrays.toL(states[i], Comparator.comparingDouble(state -> state.logDensity(temperingParameters.get(i))));
////      Arrays.sort(states[j], Comparator.comparingDouble(state -> state.logDensity(temperingParameters.get(j))));
//      
//      SummaryStatistics averageAcceptPr = new SummaryStatistics();
//      // then do each accept reject
//      for (int particleIndex = 0; particleIndex < nParticlesPerTemperature; particleIndex++)
//      {
//        double logRatio = 
//            states[i][particleIndex].logDensity(temperingParameters.get(j)) + states[j][particleIndex].logDensity(temperingParameters.get(i))
//          - states[i][particleIndex].logDensity(temperingParameters.get(i)) - states[j][particleIndex].logDensity(temperingParameters.get(j));
//        double acceptPr = Math.min(1.0, Math.exp(logRatio));
////        if (Double.isNaN(acceptPr))
////          acceptPr = 0.0; // should only happen right at the beginning
////        if (random.nextBernoulli(acceptPr))
////          doSwap(i, particleIndex);
//        averageAcceptPr.addValue(acceptPr);
//      }
//      System.out.println("avg1 " + averageAcceptPr.getMean());
//      
//    }
    
    // sort in place the two temperature by their respective annealed logDensities
    Arrays.sort(states[i], Comparator.comparingDouble(state -> state.logDensity(temperingParameters.get(i))));
    Arrays.sort(states[j], Comparator.comparingDouble(state -> state.logDensity(temperingParameters.get(j))));
    
    SummaryStatistics averageAcceptPr = new SummaryStatistics();
    // then do each accept reject
    for (int particleIndex = 0; particleIndex < nParticlesPerTemperature; particleIndex++)
    {
      double logRatio = 
          states[i][particleIndex].logDensity(temperingParameters.get(j)) + states[j][particleIndex].logDensity(temperingParameters.get(i))
        - states[i][particleIndex].logDensity(temperingParameters.get(i)) - states[j][particleIndex].logDensity(temperingParameters.get(j));
      double acceptPr = Math.min(1.0, Math.exp(logRatio));
      if (Double.isNaN(acceptPr))
        acceptPr = 0.0; // should only happen right at the beginning
      if (random.nextBernoulli(acceptPr))
        doSwap(i, particleIndex);
      averageAcceptPr.addValue(acceptPr);
    }
//    System.out.println("avg2 " + averageAcceptPr.getMean());
    return averageAcceptPr.getMean();
  }
  
  private void doSwap(int i, int particleIndex) 
  {
    int j = i + 1;
    SampledModel tmp = states[i][particleIndex];
    states[i][particleIndex] = states[j][particleIndex];
    states[j][particleIndex] = tmp;
    states[i][particleIndex].setExponent(temperingParameters.get(i));
    states[j][particleIndex].setExponent(temperingParameters.get(j));
  }
  
  public int nChains()
  {
    return states.length;
  }
  
  public void initialize(SampledModel prototype, Random random)
  {
    List<SampledModel> initStates = new ArrayList<>();
    temperingParameters = ladder.temperingParameters(nChains.orElse(nThreads.numberAvailable()));
    if (temperingParameters.get(0) != 1.0)
      throw new RuntimeException();
    System.out.println("Temperatures: " + temperingParameters);
    int nChains = temperingParameters.size();
    states = cloneParticles(initStates.isEmpty() ? defaultInit(prototype, nChains, random) : (SampledModel[]) initStates.toArray(), nParticlesPerTemperature);
    swapAcceptPrs = new SummaryStatistics[nChains - 1];
    for (int i = 0; i < nChains - 1; i++)
      swapAcceptPrs[i] = new SummaryStatistics();
    parallelRandomStreams =  Random.parallelRandomStreams(random, nChains);
  }
  
  private static SampledModel[][] cloneParticles(SampledModel[] models, int nParticlesPerTemperature) 
  {
    SampledModel[][] result = new SampledModel[models.length][nParticlesPerTemperature];
    for (int tempIndex = 0; tempIndex < models.length; tempIndex++) 
    {
      SampledModel model = models[tempIndex];
      result[tempIndex][0] = model;
      for (int pIndex = 1; pIndex < nParticlesPerTemperature; pIndex++)
        result[tempIndex][pIndex] = model.duplicate();
    }
    return result;
  }

  private SampledModel [] defaultInit(SampledModel prototype, int nChains, Random random)
  {
    SampledModel [] result = (SampledModel []) new SampledModel[nChains];
    for (int i = 0; i < nChains; i++)
    {
      result[i] = prototype.duplicate();
      result[i].setExponent(temperingParameters.get(i)); 
    }
    return result;
  }
}

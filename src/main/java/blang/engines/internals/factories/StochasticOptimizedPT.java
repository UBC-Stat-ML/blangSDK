package blang.engines.internals.factories;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.apache.commons.math3.stat.descriptive.DescriptiveStatistics;
import org.apache.commons.math3.stat.descriptive.StatisticalSummary;

import com.google.common.collect.Range;

import bayonet.distributions.Random;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.runtime.SampledModel;
import briefj.BriefParallel;

public class StochasticOptimizedPT extends PT {
  
  @Arg       @DefaultValue("100000")
  public int maxAdaptIter = 100000;
  
  @Arg                 @DefaultValue("1000")
  public int rollingStatsWindowSize = 1000;
  
  @Arg                             @DefaultValue("0.1")
  public double checkIfCanMakeZeroIfSmallerThan = 0.1;
  
  @Arg           
  public Optional<Double> robbinsMonroExponent = Optional.empty();
  
  @Arg            @DefaultValue("0.05")
  public double adaptTolerence = 0.05;
  
  @Arg           @DefaultValue("MMV")
  public Scheme scheme = Scheme.MMV;
  
  public static enum Scheme 
  {
    ARR, // ATCHADE, ROBERTS, ROSENTHAL
    MMV  // MIASOJEDOW, MOULINES, VIHOLA
  }
  
  private boolean adapt() {
    double exponent = robbinsMonroExponent.orElse(scheme == Scheme.ARR ? 1.0 : 0.6);
    double target = targetAccept.orElse(0.23);
    final int i = temperingParameters.size() - 1; // currently the last chain index
    if (temperingParameters.get(i) == 0.0)
      throw new RuntimeException();
    grow(); // add i + 1
    List<Double> parameters = new ArrayList<>(temperingParameters);
    double rho = 1.0;
    double beta = parameters.get(i);
    DescriptiveStatistics rollingStats = new DescriptiveStatistics(rollingStatsWindowSize);
    boolean success = false;
    adaptLoop : for (int n = 0; n < maxAdaptIter; n++)
    {
      double betaPrime = beta / (1.0 + (scheme == Scheme.ARR ? 1.0 : beta) * Math.exp(rho));
      parameters.set(i+1, betaPrime);
      setAnnealingParameters(parameters);
      moveTwo(i, i+1);
      double mhRatio = swapKernel(parallelRandomStreams[0], i);
      rho = rho + (mhRatio - target) / Math.pow(n + 1.0, exponent);
      rollingStats.addValue(mhRatio);
      if (credibleIntervalStatus(rollingStats, target, adaptTolerence) == IntervalStatus.ENCLOSES) 
      {
        success = true;
        break adaptLoop;
      }
    }
    if (!success)
      return false;
    
    final double candidateBetaPrime = parameters.get(i+1);
    
    // if close to zero, check if can go all the way to zero
    if (candidateBetaPrime < checkIfCanMakeZeroIfSmallerThan)
    {
      parameters.set(i+1, 0.0);
      setAnnealingParameters(parameters);
      success = false;
      rollingStats = new DescriptiveStatistics(rollingStatsWindowSize);
      shrinkToZeroLoop : for (int n = 0; n < maxAdaptIter; n++)
      {
        moveTwo(i, i+1);
        double mhRatio = swapKernel(parallelRandomStreams[0], i);
        rollingStats.addValue(mhRatio);
        IntervalStatus intervalStatus = credibleIntervalStatus(rollingStats, target, adaptTolerence);
        if (intervalStatus == IntervalStatus.ENCLOSES) 
        {
          success = true;
          break shrinkToZeroLoop;
        }
        else if (intervalStatus == IntervalStatus.DISJOINT)
          break shrinkToZeroLoop;
        else
          ; // continue!
      }
      if (!success)
      {
        parameters.set(i+1, candidateBetaPrime);
        setAnnealingParameters(parameters);
      }
    }
    return true;
  }
  
  private void grow() {
    SampledModel[] newStates = new SampledModel[temperingParameters.size() + 1];
    for (int j = 0; j < temperingParameters.size(); j++)
      newStates[j] = states[j];
    newStates[temperingParameters.size()] = newStates[temperingParameters.size() - 1].duplicate();
    states = newStates;
    List<Double> newAnnealParam = new ArrayList<>(temperingParameters);
    newAnnealParam.add(0.0);
    setAnnealingParameters(newAnnealParam);
    swapIndicators = new boolean[nChains()]; 
    parallelRandomStreams =  Random.parallelRandomStreams(parallelRandomStreams[0], newAnnealParam.size());
  }

  /**
   * Check if 90% C.I. is all contained within (target-width, target+width)
   */
  private static IntervalStatus credibleIntervalStatus(StatisticalSummary summary, double target, double width) 
  {
    double estimatedMean = summary.getMean();
    double estimatedStdDev = summary.getStandardDeviation();
    double delta = 1.645 * estimatedStdDev / Math.sqrt(summary.getN());
    double leftCI = estimatedMean - delta;
    double rightCI = estimatedMean + delta;
    Range<Double> targetInterval = Range.closed(target - width, target + width);
    Range<Double> estimatedInterval = Range.closed(leftCI, rightCI);
    if (targetInterval.encloses(estimatedInterval))
      return IntervalStatus.ENCLOSES;
    else if (!targetInterval.isConnected(estimatedInterval))
      return IntervalStatus.DISJOINT;
    else
      return IntervalStatus.UNK;
  }
  
  static enum IntervalStatus { DISJOINT, ENCLOSES, UNK }
  
  private void moveTwo(int i, int j) {
    BriefParallel.process(2, nThreads.numberAvailable(), k -> 
    {
      int chainIndex = k == 0 ? i : j;
      Random random = parallelRandomStreams[chainIndex];
      SampledModel current = states[chainIndex];
      if (temperingParameters.get(chainIndex) == 0 && usePriorSamples)
        current.forwardSample(random, false);
      else
        current.posteriorSamplingScan(random, nPassesPerScan); 
    });
  }
  
  @Override
  public void performInference() 
  {
    if (temperingParameters.size() != 1)
      throw new RuntimeException();
    
    // adapt phase
    adapt : while (temperingParameters.get(temperingParameters.size() - 1) != 0.0)
    {
      System.out.println("Adaptation: adding chain " + (1+temperingParameters.size()));
      boolean success = adapt();
      if (!success && temperingParameters.get(temperingParameters.size() - 1) != 0.0) {
        temperingParameters.set(temperingParameters.size() - 1, 0.0);
        setAnnealingParameters(temperingParameters);
        break adapt;
      }
    }
    
    this.adaptFraction = 0.0;
    super.performInference();
  }
  
  @Override
  public void setSampledModel(SampledModel model) 
  {
    nChains = Optional.of(1);
    initialize(model, random);
  }
}

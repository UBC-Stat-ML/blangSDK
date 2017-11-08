package blang.validation.internals.fixtures;

import java.util.List;
import bayonet.distributions.Random;

import blang.core.LogScaleFactor;
import blang.core.WritableRealVar;
import blang.distributions.Generators;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.SampledVariable;
import blang.mcmc.Sampler;


public class FixedIntervalRealSliceSampler implements Sampler
{
  @SampledVariable
  protected WritableRealVar variable;
  
  @ConnectedFactor
  protected List<LogScaleFactor> numericFactors;
  
  private static final double initialWindowSize = 1.0;
  
  public static FixedIntervalRealSliceSampler build(WritableRealVar variable, List<LogScaleFactor> numericFactors)
  {
    FixedIntervalRealSliceSampler result = new FixedIntervalRealSliceSampler();
    result.variable = variable;
    result.numericFactors = numericFactors;
    return result;
  }
  
  public void execute(Random random)
  {
    // sample slice
    final double logSliceHeight = nextSliceHeight(random); // log(Y) in Neal's paper
    final double oldState = variable.doubleValue();        // x0 in Neal's paper
   
    double 
      leftProposalEndPoint = oldState - initialWindowSize * random.nextDouble(), // L in Neal's paper
      rightProposalEndPoint = leftProposalEndPoint + initialWindowSize;          // R in Neal's paper
    
    // shrinkage procedure
    double 
      leftShrankEndPoint = leftProposalEndPoint,   // bar L in Neal's paper
      rightShrankEndPoint = rightProposalEndPoint; // bar R in Neal's paper
    while (true) 
    {
      final double newState = Generators.uniform(random, leftShrankEndPoint, rightShrankEndPoint); // x1 in Neal's paper
      if (logSliceHeight < logDensityAt(newState))
      {
        variable.set(newState);
        return;
      }
      if (useShrink)
      {
        if (newState < oldState)
          leftShrankEndPoint = newState;
        else
          rightShrankEndPoint = newState;
      }
      
    }
  }
  
  public static boolean useShrink = true;

  private double nextSliceHeight(Random random)
  {
    return logDensity() - Generators.unitRateExponential(random); 
  }
  
  private double logDensityAt(double x)
  {
    variable.set(x);
    return logDensity();
  }
  
  private double logDensity() {
    double sum = 0.0;
    for (LogScaleFactor f : numericFactors)
      sum += f.logDensity();
    if (Double.isNaN(sum))
      throw new RuntimeException();
    return sum;
  }
  
  public boolean setup() 
  {
    return true;
  }
}
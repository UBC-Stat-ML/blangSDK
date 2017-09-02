package blang.runtime;

import bayonet.distributions.Random;
import blang.algo.AnnealingKernels;

public class ChangeOfMeasureKernel implements AnnealingKernels<SampledModel>
{
  private final SampledModel prototype;
  
  public ChangeOfMeasureKernel(SampledModel prototype) 
  {
    this.prototype = prototype;
  }

  @Override
  public SampledModel sampleInitial(Random random) 
  {
    SampledModel copy = prototype.duplicate();
    copy.forwardSample(random);
    copy.dropForwardSimulator();
    return copy;
  }

  @Override
  public SampledModel sampleNext(Random random, SampledModel current, double temperature) 
  {
    current.setExponent(temperature);
    current.forwardSample(random); 
    return current;
  }

  @Override
  public boolean inPlace() 
  {
    return true;
  }

  @Override
  public SampledModel deepCopy(SampledModel particle) 
  {
    return particle.duplicate();
  }

}

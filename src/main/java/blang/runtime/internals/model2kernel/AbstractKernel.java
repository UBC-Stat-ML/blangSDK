package blang.runtime.internals.model2kernel;

import bayonet.distributions.Random;
import blang.engines.internals.AnnealingKernels;
import blang.runtime.SampledModel;

public abstract class AbstractKernel implements AnnealingKernels<SampledModel> 
{
  private final SampledModel prototype;
  
  public AbstractKernel(SampledModel prototype) 
  {
    this.prototype = prototype;
  }

  protected SampledModel sampleInitial(Random random, boolean dropForwardSimulator) 
  {
    SampledModel copy = prototype.duplicate();
    copy.forwardSample(random, false);
    if (dropForwardSimulator)
      copy.dropForwardSimulator();
    return copy;
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

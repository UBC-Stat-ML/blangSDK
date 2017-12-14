package blang.runtime.internals.model2kernel;

import bayonet.distributions.Random;
import blang.runtime.SampledModel;

public class ExactSamplerKernel extends AbstractKernel
{
  public ExactSamplerKernel(SampledModel prototype) 
  {
    super(prototype);
  }

  @Override
  public SampledModel sampleNext(Random random, SampledModel current, double temperature) 
  {
    if (temperature != 0.0)
      throw new RuntimeException();
    if (current == null)
      return sampleInitial(random, false);
    current.forwardSample(random, false);
    return current;
  }
}

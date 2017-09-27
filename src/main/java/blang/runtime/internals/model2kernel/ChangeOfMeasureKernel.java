package blang.runtime.internals.model2kernel;

import bayonet.distributions.Random;
import blang.runtime.SampledModel;

public class ChangeOfMeasureKernel extends AbstractKernel
{
  public ChangeOfMeasureKernel(SampledModel prototype) 
  {
    super(prototype);
  }

  @Override
  public SampledModel sampleNext(Random random, SampledModel current, double temperature) 
  {
    if (current == null)
    {
      if (temperature != 0.0)
        throw new RuntimeException();
      return sampleInitial(random, true);
    }
    current.setExponent(temperature);
    current.posteriorSamplingStep_deterministicScanAndShuffle(random); 
    return current;
  }
}

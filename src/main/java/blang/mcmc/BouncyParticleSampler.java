package blang.mcmc;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.LogScaleFactor;
import blang.distributions.NormalField;
import blang.mcmc.internals.SamplerBuilderContext;

public class BouncyParticleSampler implements Sampler 
{
  @SampledVariable(skipFactorsFromSampledModel = true)
  public NormalField field;
  
  @ConnectedFactor
  public List<LogScaleFactor> likelihoods;

  @Override
  public void execute(Random rand) 
  {
    // TODO Auto-generated method stub
    
  }

  @Override
  public boolean setup(SamplerBuilderContext context) 
  {
//    for (LogScaleFactor factor : )
    return false;
  }

}

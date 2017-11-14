package blang.mcmc;

import bayonet.distributions.Random;
import blang.distributions.NormalField;
import blang.mcmc.internals.SamplerBuilderContext;

public class BouncyParticleSampler implements Sampler 
{
  @SampledVariable
  public NormalField field;
  
  

  @Override
  public void execute(Random rand) 
  {
    // TODO Auto-generated method stub
    
  }

  @Override
  public boolean setup(SamplerBuilderContext context) 
  {
   System.out.println("Matched BPS correctly!" + field);
    return false;
  }

}

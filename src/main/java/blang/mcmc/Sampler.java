package blang.mcmc;

import bayonet.distributions.Random;
import blang.mcmc.internals.SamplerBuilderContext;




public interface Sampler 
{

  public void execute(Random rand);
  
  /**
   * @return Is the sampler compatible?
   */
  public boolean setup(SamplerBuilderContext context);
  
}

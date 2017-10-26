package blang.mcmc;

import bayonet.distributions.Random;




public interface Sampler 
{

  public void execute(Random rand);
  
  /**
   * @return If this sampler is actually compatible.
   */
  public boolean setup();
}

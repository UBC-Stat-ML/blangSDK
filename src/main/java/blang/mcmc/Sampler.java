package blang.mcmc;

import bayonet.distributions.Random;




public interface Sampler 
{

  public void execute(Random rand);
  
  /**
   * @return Is the sampler is actually compatible?
   */
  public boolean setup();
  
}

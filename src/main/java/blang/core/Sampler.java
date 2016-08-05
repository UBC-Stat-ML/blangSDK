package blang.core;

import java.util.Random;

import blang.mcmc.Operator;




public interface Sampler extends Operator
{
  /*
   * Todo: need facilities for
   *  - command line options
   *  - logging 
   *      - summary stats such as acceptance rate
   *      - samples
   *  - adaptation
   *  - bailing out
   *  - annealing
   *      - remove -Inf in support
   *      - exponents for AIS/parallel tempering/simulated annealing
   *  - return an order of magnitude of the number of FLOPS required
   */
  
  public void execute(Random rand);
}

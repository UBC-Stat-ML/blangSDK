package blang.engines.internals;

import bayonet.distributions.Random;

public interface AnnealingKernels<P>
{
  /**
   * Sample from a pi_t invariant kernel where t = temperature
   * 
   * If current is null sampled exactly (usually only possible if annealingParameter = 0)
   */
  P sampleNext(Random random, P current, double annealingParameter);
  
  /**
   * Whether sampleNext(.) changes the current state in place.
   */
  boolean inPlace();
  
  /**
   * Only requires if proposal is in place.
   */
  P deepCopy(P particle);
}
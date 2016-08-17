package blang.mcmc;

import java.util.Random;

import blang.types.Real.RealImpl;



public class RealNaiveMHSampler extends MHSampler<RealImpl>
{
  @Override
  public void propose(Random random, Callback callback)
  {
    final double oldValue = variable.doubleValue();
    callback.setProposalLogRatio(0.0);
    variable.set(oldValue + random.nextGaussian());
    if (!callback.sampleAcceptance())
      variable.set(oldValue);
  }
}

package blang.mcmc;

import bayonet.distributions.Random;

import blang.core.WritableRealVar;
import blang.mcmc.internals.Callback;



public class RealNaiveMHSampler extends MHSampler<WritableRealVar>
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

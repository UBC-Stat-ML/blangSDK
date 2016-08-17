package blang.mcmc;

import java.util.Random;

import blang.types.BoolVar.BoolImpl;


public class BoolMHSampler extends MHSampler<BoolImpl> 
{
  @Override
  public void propose(Random random, Callback callback)
  {
    final boolean oldValue = variable.booleanValue();
    callback.setProposalLogRatio(0.0);
    variable.set(!oldValue);
    if (!callback.sampleAcceptance())
      variable.set(oldValue);
  }
}

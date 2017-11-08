package blang.validation.internals.fixtures;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.LogScaleFactor;
import blang.core.WritableRealVar;
import blang.mcmc.MHSampler;
import blang.mcmc.SampledVariable;
import blang.mcmc.internals.Callback;




public class RealNaiveMHSampler extends MHSampler
{
  @SampledVariable
  WritableRealVar variable;
  
  public static RealNaiveMHSampler build(WritableRealVar variable, List<LogScaleFactor> numericFactors)
  {
    RealNaiveMHSampler result = new RealNaiveMHSampler();
    result.variable = variable;
    result.numericFactors = numericFactors;
    return result;
  }
  
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

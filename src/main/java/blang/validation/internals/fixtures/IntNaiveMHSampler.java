package blang.validation.internals.fixtures;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.LogScaleFactor;
import blang.core.WritableIntVar;
import blang.mcmc.MHSampler;
import blang.mcmc.internals.Callback;




public class IntNaiveMHSampler extends MHSampler<WritableIntVar>
{
  public static IntNaiveMHSampler build(WritableIntVar variable, List<LogScaleFactor> numericFactors)
  {
    IntNaiveMHSampler result = new IntNaiveMHSampler();
    result.variable = variable;
    result.numericFactors = numericFactors;
    return result;
  }
  
  @Override
  public void propose(Random random, Callback callback)
  {
    final int oldValue = variable.intValue();
    callback.setProposalLogRatio(0.0);
    variable.set(oldValue + (random.nextBoolean() ? 1 : -1));
    if (!callback.sampleAcceptance())
      variable.set(oldValue);
  }
}

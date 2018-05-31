package blang.validation.internals.fixtures;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.Constrained;
import blang.core.LogScaleFactor;
import blang.core.WritableIntVar;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.MHSampler;
import blang.mcmc.SampledVariable;
import blang.mcmc.internals.Callback;



/**
 * Warning: not a general purpose move - specialized to SmallHMM test or similar simple binary cases
 */
public class IntNaiveMHSampler extends MHSampler
{
  @SampledVariable
  WritableIntVar variable;
  
  @ConnectedFactor
  List<Constrained> constrained;
  
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
    variable.set(1 - oldValue);
    if (!callback.sampleAcceptance())
      variable.set(oldValue);
  }
}

package blang.mcmc

import bayonet.distributions.Random
import blang.core.Constrained
import blang.core.LogScaleFactor
import blang.core.WritableIntVar
import blang.distributions.Categorical
import java.util.List

class CategoricalSampler implements Sampler {
  
  @SampledVariable
  Categorical categorical
  
  @ConnectedFactor
  Constrained constrained
  
  @ConnectedFactor
  List<LogScaleFactor> numericFactors

  override void execute(Random rand) {
    val int max = categorical.probabilities.nEntries
    val IntSliceSampler sampler = IntSliceSampler.build(categorical.getRealization as WritableIntVar, numericFactors, 0, max)
    sampler.execute(rand)
  }
}

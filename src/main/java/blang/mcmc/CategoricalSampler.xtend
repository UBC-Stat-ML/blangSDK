package blang.mcmc

import bayonet.distributions.Random
import blang.core.Factor
import blang.mcmc.internals.SamplerBuilderContext
import java.util.List
import blang.distributions.Categorical
import blang.runtime.internals.objectgraph.StaticUtils
import blang.core.Constrained
import blang.core.LogScaleFactor
import java.util.ArrayList
import blang.core.WritableIntVar

class CategoricalSampler implements Sampler {
  
  @SampledVariable
  Categorical categorical
  
  @ConnectedFactor 
  List<Factor> _factors
  
  List<LogScaleFactor> logScaleFactors = null

  override void execute(Random rand) {
    val int max = categorical.probabilities.nEntries
    val IntSliceSampler sampler = IntSliceSampler.build(categorical.getRealization as WritableIntVar, logScaleFactors, 0, max)
    sampler.execute(rand)
  }

  @SuppressWarnings("unchecked") 
  override boolean setup(SamplerBuilderContext context) {
    _factors = null
    logScaleFactors = new ArrayList
    var boolean constrainedFound = false
    for (Factor f : context.connectedFactors(StaticUtils.node(categorical.getRealization))) {
      if (f instanceof Constrained) {
        if (constrainedFound) {
          return false
        }
        constrainedFound = true
      }
      else if (f instanceof LogScaleFactor) {
        logScaleFactors.add(f as LogScaleFactor)
      }
      else
        return false
    }
    return true
  }

}

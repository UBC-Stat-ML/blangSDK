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
    if (!context.isLatent(categorical.getRealization) ||
        !(categorical.getRealization instanceof WritableIntVar)
    ) {
      return false
    }
    /*
     * More complex init needed to avoid pulling too many 
     * dependencies (i.e. those coming from categorical.probabilities
     */
    _factors = null
    logScaleFactors = extractFactorsFor(categorical.getRealization, context)
    if (logScaleFactors === null)
      return false
    return true
  }
  
  static def List<LogScaleFactor> extractFactorsFor(Object object, SamplerBuilderContext context) {
    val result = new ArrayList
    var boolean constrainedFound = false
    for (Factor f : context.connectedFactors(StaticUtils.node(object))) {
      if (f instanceof Constrained) {
        if (constrainedFound) {
          return null
        }
        constrainedFound = true
      }
      else if (f instanceof LogScaleFactor) {
        result.add(f as LogScaleFactor)
      }
      else
        return null
    }
    return result
  }

}

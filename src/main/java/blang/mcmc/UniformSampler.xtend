package blang.mcmc

import bayonet.distributions.Random
import blang.core.Factor
import blang.mcmc.internals.SamplerBuilderContext
import java.util.List
import blang.core.LogScaleFactor
import blang.core.WritableIntVar
import blang.distributions.DiscreteUniform

class UniformSampler implements Sampler {
  
  @SampledVariable
  DiscreteUniform uniform
  
  @ConnectedFactor 
  List<Factor> _factors
  
  List<LogScaleFactor> logScaleFactors = null

  override void execute(Random rand) {
    val int min = uniform.minInclusive.intValue
    val int max = uniform.maxExclusive.intValue
    val IntSliceSampler sampler = IntSliceSampler.build(uniform.getRealization as WritableIntVar, logScaleFactors, min, max)
    sampler.execute(rand)
  }

  @SuppressWarnings("unchecked") 
  override boolean setup(SamplerBuilderContext context) {
    if (!context.isLatent(uniform.getRealization) ||
        !(uniform.getRealization instanceof WritableIntVar)
    ) {
      return false
    }
    /*
     * More complex init needed to avoid pulling too many 
     * dependencies (i.e. those coming from categorical.probabilities
     */
    _factors = null
    logScaleFactors = CategoricalSampler::extractFactorsFor(uniform.getRealization, context)
    if (logScaleFactors === null)
      return false
    return true
  }
}

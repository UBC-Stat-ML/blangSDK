package blang.mcmc

import bayonet.distributions.Random
import blang.core.Constrained
import blang.types.DenseSimplex
import blang.core.LogScaleFactor
import java.util.List
import blang.mcmc.internals.SamplerBuilderContext
import blang.mcmc.internals.SimplexWritableVariable

class SimplexSampler implements Sampler {
  @SampledVariable DenseSimplex simplex
  @ConnectedFactor List<LogScaleFactor> numericFactors
  @ConnectedFactor Constrained constrained
  
  override void execute(Random rand) {
    val int sampledDim = rand.nextInt(simplex.nEntries)
    val SimplexWritableVariable sampled 
      = new SimplexWritableVariable(sampledDim, simplex)
    val RealSliceSampler slicer 
      = RealSliceSampler::build(sampled, numericFactors, 0.0, sampled.sum)
    slicer.execute(rand) 
  }
  
  override boolean setup(SamplerBuilderContext context) {
    return 
      simplex.nEntries >= 2 &&
      constrained !== null && 
      constrained.object instanceof DenseSimplex
  }
}
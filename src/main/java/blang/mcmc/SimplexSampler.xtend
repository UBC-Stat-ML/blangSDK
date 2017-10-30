package blang.mcmc

import bayonet.distributions.Random;
import blang.core.ConstrainedFactor
import blang.mcmc.internals.Callback
import blang.types.DenseSimplex

class SimplexSampler extends MHSampler {
  
  @SampledVariable
  DenseSimplex variable
  
  @ConnectedFactor
  ConstrainedFactor constrained
  
  override boolean setup() {
    return constrained !== null && constrained.object instanceof DenseSimplex
  }
  
  override void propose(Random random, Callback callback) {
    if (variable.nEntries  < 2) {
      throw new RuntimeException
    }
    val int sampledDim = random.nextInt(variable.nEntries - 1)
    val int lastDim = variable.nEntries - 1
    val double oldValue = variable.get(sampledDim)
    val double lastValue = variable.get(lastDim)
    val double max = oldValue + lastValue
    val double proposal = random.nextDouble() * max
    variable.setPair(
      sampledDim, proposal,
      lastDim, max - proposal
    )
    callback.proposalLogRatio = 0.0 
    if (!callback.sampleAcceptance) {
      variable.setPair(
        sampledDim, oldValue,
        lastDim, lastValue
      )
    }
  }
}
package blang.mcmc

import blang.types.Simplex
import bayonet.distributions.Random;
import blang.core.ConstrainedFactor
import blang.mcmc.internals.Callback

class SimplexSampler extends MHSampler<Simplex> {
  
  @ConnectedFactor
  protected ConstrainedFactor constrained
  
  override boolean setup() {
    return constrained !== null && constrained.object instanceof Simplex
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
    variable.set(sampledDim, proposal)
    variable.set(lastDim, max - proposal)
    callback.proposalLogRatio = 0.0 
    if (!callback.sampleAcceptance) {
      variable.set(sampledDim, oldValue)
      variable.set(lastDim, lastValue)
    }
  }
}
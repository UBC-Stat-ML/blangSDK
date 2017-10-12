package blang.mcmc

import java.util.Random
import blang.core.ConstrainedFactor
import blang.mcmc.internals.Callback
import blang.runtime.internals.objectgraph.MatrixConstituentNode
import blang.types.Simplex

class SimplexSampler extends MHSampler<MatrixConstituentNode> {
  
  @ConnectedFactor
  protected ConstrainedFactor constrained
  
  override boolean setup() {
    if (constrained === null || !(constrained.object instanceof Simplex)) {
      return false // do not use if not constrained
    }
    // no need to resample last entry
    return index !== variable.container.nEntries - 1
  }
  
  def private int index() {
    return Math.max(variable.row, variable.col)
  }
  
  override void propose(Random random, Callback callback) {
    val int sampledDim = index
    val int lastDim = variable.container.nEntries - 1
    val double oldValue = variable.container.get(sampledDim)
    val double lastValue = variable.container.get(lastDim)
    val double max = oldValue + lastValue
    val double proposal = random.nextDouble() * max
    variable.container.set(sampledDim, proposal)
    variable.container.set(lastDim, max - proposal)
    callback.proposalLogRatio = 0.0 
    if (!callback.sampleAcceptance) {
      variable.container.set(sampledDim, oldValue)
      variable.container.set(lastDim, lastValue)
    }
  }
}
package blang.mcmc

import bayonet.distributions.Random;
import blang.core.ConstrainedFactor
import blang.types.DenseSimplex
import blang.core.WritableRealVar
import org.eclipse.xtend.lib.annotations.Data
import blang.core.LogScaleFactor
import java.util.List
import blang.mcmc.internals.SamplerBuilderContext

class SimplexSampler implements Sampler {
  
  @SampledVariable
  DenseSimplex variable
  
  @ConnectedFactor
  ConstrainedFactor constrained
  
  @ConnectedFactor
  List<LogScaleFactor> numericFactors
  
  override boolean setup(SamplerBuilderContext context) {
    return constrained !== null && constrained.object instanceof DenseSimplex
  }
  
  override void execute(Random rand) {
    if (variable.nEntries  < 2) {
      throw new RuntimeException
    }
    val int sampledDim = rand.nextInt(variable.nEntries)
    val SimplexWritableVariable sampled = new SimplexWritableVariable(sampledDim, variable)
    val RealSliceSampler slicer = RealSliceSampler::build(sampled, numericFactors, 0.0, sampled.sum)
    slicer.execute(rand) 
  }
  
  @Data
  private static class SimplexWritableVariable implements WritableRealVar {
    
    val int index
    val DenseSimplex simplex
    
    def double sum()
    {
      return simplex.get(index) + simplex.get(nextIndex);
    }
    
    def int nextIndex() {
      if (index === simplex.nEntries - 1) {
        return 0
      } else {
        return index + 1
      }
    }
    
    override set(double value) {
      val sum = sum()
      val complement = Math.max(0.0, sum - value) // avoid rounding errors creating negative values
      simplex.setPair(index, value, nextIndex, complement)
    }
    
    override doubleValue() {
      return simplex.get(index)
    }
  }
}
package blang.mcmc.internals

import org.eclipse.xtend.lib.annotations.Data
import blang.core.WritableRealVar
import blang.types.DenseSimplex

@Data
  class SimplexWritableVariable implements WritableRealVar {
    
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
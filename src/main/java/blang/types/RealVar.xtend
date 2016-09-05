package blang.types

import blang.mcmc.RealNaiveMHSampler
import blang.mcmc.Samplers
import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.objectgraph.SkipDependency
import xlinear.Matrix

@FunctionalInterface
interface RealVar { 
  
  def double doubleValue() 
  
  @Samplers(RealNaiveMHSampler)
  static interface WritableRealVar extends RealVar {
    def void set(double value)
  }
  
  static class RealScalar implements WritableRealVar { 
    
    var double value = 0.0
    
    new (double value) { this.value = value }
    
    override double doubleValue() {
      return value
    }
    
    override void set(double newValue) {
      this.value = newValue
    } 
    
    override String toString() {
      return Double.toString(value)
    }
  }
  
  @Data
  static class RealMatrixComponent implements WritableRealVar {
    val int rowIndex
    val int colIndex
    
    /**
     * We skip because there is a special exploration rule 
     * with Matrix that creates canonical components.
     */
    @SkipDependency
    val Matrix containerMatrix
    
    override set(double value) {
      containerMatrix.set(rowIndex, colIndex, value)
    }
    
    override doubleValue() {
      return containerMatrix.get(rowIndex, colIndex)
    }
    
    override String toString() {
      return Double.toString(doubleValue())
    }
  }
}
package blang.types

import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.internals.objectgraph.SkipDependency
import xlinear.Matrix
import blang.core.WritableRealVar
import blang.mcmc.RealNaiveMHSampler
import blang.mcmc.Samplers

@Data
@Samplers(RealNaiveMHSampler) 
class RealMatrixComponent implements WritableRealVar {
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
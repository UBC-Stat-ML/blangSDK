package blang.types

import org.eclipse.xtend.lib.annotations.Delegate
import blang.mcmc.Samplers
import blang.mcmc.SimplexSampler
import org.eclipse.xtend.lib.annotations.Accessors
import blang.types.internals.Delegator
import xlinear.DenseMatrix
import bayonet.math.NumericalUtils

import static extension xlinear.MatrixExtensions.*
import xlinear.internals.MatrixVisitorEditInPlace

/**
 * 
 */
@Samplers(SimplexSampler)
class DenseSimplex implements Simplex, DenseMatrix, Delegator<DenseMatrix> {
  @Accessors(PUBLIC_GETTER)
  @Delegate DenseMatrix delegate
  
  new (DenseMatrix matrix) {
    NumericalUtils::checkIsClose(matrix.sum, 1.0)
    this.delegate = matrix
  }
  
  override void editInPlace(MatrixVisitorEditInPlace visitor) {
    delegate.editInPlace(visitor)
    NumericalUtils::checkIsClose(this.sum, 1.0)
  }
  
  def void setPair(int index1, double value1, int index2, double value2) {
    val double old = get(index1) + get(index2)
    NumericalUtils::checkIsClose(old, value1 + value2)
    delegate.set(index1, value1)
    delegate.set(index2, value2)
  }
  
  override void set(int i, int j, double value) {
    throw new RuntimeException("Use setPair instead");
  }
  
  override void set(int i, double value) {
    throw new RuntimeException("Use setPair instead");
  }
  
}
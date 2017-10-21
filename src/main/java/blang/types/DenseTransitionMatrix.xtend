package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import org.eclipse.xtend.lib.annotations.Accessors
import blang.types.internals.Delegator
import xlinear.DenseMatrix
import xlinear.internals.MatrixVisitorEditInPlace

import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils

@Data class DenseTransitionMatrix implements TransitionMatrix, DenseMatrix, Delegator<DenseMatrix> {
  @Accessors(PUBLIC_GETTER)
  @Delegate
  val DenseMatrix delegate 
  
  override DenseSimplex row(int i) {
    return new DenseSimplex(delegate.row(i)) 
  }
  
  override void editInPlace(MatrixVisitorEditInPlace visitor) {
    delegate.editInPlace(visitor)
    for (var int rowIndex = 0; rowIndex < nRows; rowIndex++) {
      NumericalUtils::checkIsClose(row(rowIndex).sum, 1.0)
    }
  }
}
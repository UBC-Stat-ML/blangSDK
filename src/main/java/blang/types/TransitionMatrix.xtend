package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import org.eclipse.xtend.lib.annotations.Accessors
import blang.types.internals.Delegator
import xlinear.DenseMatrix

@Data class TransitionMatrix implements DenseMatrix, Delegator<DenseMatrix> {
  @Accessors(PUBLIC_GETTER)
  @Delegate
  val DenseMatrix delegate 
  
  override Simplex row(int i) {
    return new Simplex(delegate.row(i)) 
  }
}
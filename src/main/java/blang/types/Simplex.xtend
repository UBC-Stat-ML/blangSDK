package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import xlinear.DenseMatrix

@Data class Simplex implements DenseMatrix {
  
  @Delegate
  val DenseMatrix probabilities
  
}
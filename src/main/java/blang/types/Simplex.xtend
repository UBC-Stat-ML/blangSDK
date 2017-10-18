package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import blang.mcmc.Samplers
import blang.mcmc.SimplexSampler
import xlinear.DenseMatrix

@Samplers(SimplexSampler)
@Data class Simplex implements DenseMatrix {
  
  @Delegate
  val public DenseMatrix probabilityMatrix
  
}
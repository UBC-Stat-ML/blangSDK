package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import blang.mcmc.Samplers
import blang.mcmc.SimplexSampler
import org.eclipse.xtend.lib.annotations.Accessors
import blang.types.internals.Delegator
import xlinear.DenseMatrix

@Samplers(SimplexSampler)
@Data class Simplex implements DenseMatrix, Delegator<DenseMatrix> {
  @Accessors(PUBLIC_GETTER)
  @Delegate DenseMatrix delegate
}
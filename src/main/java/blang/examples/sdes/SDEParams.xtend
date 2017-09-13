package blang.examples.sdes

import xlinear.DenseMatrix
import xlinear.CholeskyDecomposition
import blang.inits.Implementations

@Implementations(BrownianMotion)
interface SDEParams {
  def DenseMatrix mean(DenseMatrix position, double t, double delta)
  def CholeskyDecomposition precision(DenseMatrix position, double t, double delta)
}
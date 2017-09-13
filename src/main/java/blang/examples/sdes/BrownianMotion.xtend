package blang.examples.sdes

import xlinear.DenseMatrix
import xlinear.CholeskyDecomposition
import xlinear.SparseMatrix

import static xlinear.MatrixOperations.*

class BrownianMotion implements SDEParams {
  override DenseMatrix mean(DenseMatrix position, double t0, double t1) {
    return position
  }
  override CholeskyDecomposition precision(DenseMatrix position, double t0, double t1) {
    val SparseMatrix precision = identity(position.nEntries) / (t1 - t0); 
    // TODO: could keep around a transient cache 
    return precision.cholesky
  }
}
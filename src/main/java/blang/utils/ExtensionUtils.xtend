package blang.utils

import blang.types.IntVar
import java.util.List
import blang.types.RealVar
import java.util.ArrayList
import blang.types.IntVar.IntScalar
import blang.types.RealVar.RealScalar
import xlinear.Matrix
import blang.types.RealVar.RealMatrixComponent
import blang.types.Simplex
import xlinear.DenseMatrix
import static extension xlinear.MatrixOperations.*
import blang.types.TransitionMatrix
import bayonet.math.NumericalUtils
import java.util.Collections

class ExtensionUtils {
  
  def static RealVar getRealVar(Matrix m, int row, int col) {
    return new RealMatrixComponent(row, col, m)
  }
  
  def static RealVar getRealVar(Matrix m, int index) {
    if (!m.isVector()) 
      throw xlinear.StaticUtils::notAVectorException
    if (m.nRows() == 1)
      return getRealVar(m, 0, index)
    else
      return getRealVar(m, index, 0)
  }

  def static <T> T get(List<T> list, IntVar intVar) {
    return list.get(intVar.intValue)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
  
  private new() {}
}
package blang.utils

import blang.core.RealVar
import xlinear.Matrix
import blang.types.RealMatrixComponent
import blang.core.IntVar
import java.util.List

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
}
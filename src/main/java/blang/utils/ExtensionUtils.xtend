package blang.utils

import blang.core.IntVar
import java.util.List
import blang.core.RealVar
import xlinear.Matrix
import blang.types.RealMatrixComponent

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
  
  //// Workaround for stuff not covered by the auto-boxing / de-boxing
  
  def static double +(RealVar v1, RealVar v2) {
    return v1.doubleValue + v2.doubleValue
  }
  
  def static boolean ==(RealVar v1, RealVar v2) {
    return v1.doubleValue === v2.doubleValue
  }
  
  def static boolean ==(RealVar v1, Number v2) {
    return v1.doubleValue === v2.doubleValue
  }
  
  def static boolean ==(Number v1, RealVar v2) {
    return v1.doubleValue === v2.doubleValue
  }
  
  def static boolean ==(IntVar v1, IntVar v2) {
    return v1.intValue === v2.intValue
  }
  
  def static boolean ==(IntVar v1, Number v2) {
    return v1.intValue === v2.intValue
  }
  
  def static boolean ==(Number v1, IntVar v2) {
    return v1.intValue === v2.intValue
  }
  
  private new() {}
}
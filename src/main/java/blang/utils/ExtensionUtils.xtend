package blang.utils

import blang.types.IntVar
import java.util.List
import blang.types.RealVar

class ExtensionUtils {
  
  def static <T> T get(List<T> list, IntVar intVar) {
    return list.get(intVar.intValue)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
  
}
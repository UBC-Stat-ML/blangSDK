package blang.utils

import blang.types.IntVar
import java.util.List
import blang.types.RealVar
import blang.types.Simplex

class ExtensionUtils {
  
  def static <T> T get(List<T> list, IntVar intVar) {
    return list.get(intVar.intValue)
  }
  
    def static double get(Simplex simplex, IntVar intVar) {
    return simplex.get(intVar.intValue)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
  
//  def static boolean >=(IntVar v0, int v1) {
//    return v0.intValue >= v1
//  }
//  
//    def static boolean <=(IntVar v0, int v1) {
//    return v0.intValue <= v1
//  }
//  
//    def static boolean >(IntVar v0, int v1) {
//    return v0.intValue > v1
//  }
//  
//    def static boolean <(IntVar v0, int v1) {
//    return v0.intValue < v1
//  }
  
}
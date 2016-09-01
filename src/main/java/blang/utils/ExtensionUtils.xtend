package blang.utils

import blang.types.IntVar
import java.util.List
import blang.types.RealVar
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import java.util.Map
import blang.types.IntVar.IntImpl
import blang.types.RealVar.RealImpl

class ExtensionUtils {
  
  def static RealVar createLatentReal(double initialValue) { 
    return new RealImpl(initialValue)
  }
  
  def static IntVar createLatentInt(int initialValue) { 
    return new IntImpl(initialValue)
  }
  
  def static RealVar createConstantReal(double value) {
    return [value]
  }
  
  def static IntVar createConstantInt(int value) {
    return [value]
  }
  
  def static List<IntVar> listOfIntVars(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(createLatentInt(0))
    }
    return result
  }
  
    def static List<RealVar> listOfRealVars(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(createLatentReal(0.0))
    }
    return result
  }
  
  def static <T> T get(List<T> list, IntVar intVar) {
    return list.get(intVar.intValue)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
}
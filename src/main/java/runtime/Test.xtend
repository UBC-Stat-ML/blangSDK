package runtime

import java.util.function.Supplier
import java.lang.reflect.ParameterizedType
import blang.annotations.Param
import utils.StaticUtils
import java.lang.reflect.TypeVariable
import java.lang.reflect.Type
import java.util.Arrays

class Test {
  
  static interface X<T> {
    def T y()
  }
  
  static class ASupplier implements Supplier<String>, X<Integer> {
    
    override get() {
      throw new UnsupportedOperationException("TODO: auto-generated method stub")
    }
    
    override y() {
      throw new UnsupportedOperationException("TODO: auto-generated method stub")
    }
    
  }
  
  def public static void main(String [] args) {
    
    val Class<?> theClass = ASupplier
    
    val ParameterizedType supplierInterfaceSpec = StaticUtils::pickUnique(theClass.genericInterfaces.filter(ParameterizedType).filter[it.rawType == Supplier])
    val typeArg = StaticUtils::pickUnique(supplierInterfaceSpec.actualTypeArguments)
    
    
    println(typeArg)
    
  }
}
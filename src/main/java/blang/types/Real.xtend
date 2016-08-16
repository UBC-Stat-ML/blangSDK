package blang.types

import blang.inits.InitVia
import blang.inits.strategies.SelectImplementation
import blang.inits.Implementation

@InitVia(SelectImplementation) @Implementation(RealImpl)
@FunctionalInterface
interface Real {
  
  def double doubleValue()
  
   
  static class RealImpl implements Real {
    
    var double value
    
    override double doubleValue() {
      return value
    }
    
    def void set(double newValue) {
      this.value = newValue
    }
  }
}
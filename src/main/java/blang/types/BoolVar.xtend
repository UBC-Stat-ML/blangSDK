package blang.types

import blang.inits.DesignatedConstructor
import blang.inits.Input
import blang.mcmc.Samplers
import blang.mcmc.BoolMHSampler
import blang.runtime.ObservationProcessor
import java.util.Optional
import blang.inits.GlobalArg

@FunctionalInterface
interface BoolVar { 
  
  def boolean booleanValue()
  
  @Samplers(BoolMHSampler)    
  static class BoolImpl implements BoolVar {
    
    var boolean value
    
    new(boolean value) { this.value = value }
    
    override boolean booleanValue() {
      return value
    }
    
    def void set(boolean newValue) {
      this.value = newValue
    }
    
    override String toString() {
      return Boolean.toString(value)
    }
  }
}
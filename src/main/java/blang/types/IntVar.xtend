package blang.types

import blang.inits.DesignatedConstructor
import blang.inits.Input
import blang.mcmc.Samplers
import blang.mcmc.IntNaiveMHSampler
import blang.runtime.ObservationProcessor
import blang.inits.GlobalArg
import java.util.Optional

@FunctionalInterface
interface IntVar { 
  
  def int intValue()
  
  @Samplers(IntNaiveMHSampler)   
  static class IntImpl implements IntVar {
    
    var int value
    
    new(int value) { this.value = value }
    
    override int intValue() {
      return value
    }
    
    def void set(int newValue) {
      this.value = newValue
    }
    
    override String toString() {
      return Integer.toString(value)
    }
  }
}
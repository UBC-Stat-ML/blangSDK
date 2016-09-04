package blang.types

import blang.mcmc.IntNaiveMHSampler
import blang.mcmc.Samplers

@FunctionalInterface
interface IntVar { 
  
  def int intValue()
  
  @Samplers(IntNaiveMHSampler)   
  static class IntScalar implements IntVar {
    
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
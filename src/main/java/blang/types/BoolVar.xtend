package blang.types

import blang.mcmc.BoolMHSampler
import blang.mcmc.Samplers

@FunctionalInterface
interface BoolVar { 
  
  def boolean booleanValue()
  
  @Samplers(BoolMHSampler)   
  static class BoolScalar implements BoolVar {
    
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
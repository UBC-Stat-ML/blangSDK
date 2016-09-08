package blang.types

import blang.mcmc.IntNaiveMHSampler
import blang.mcmc.Samplers

@FunctionalInterface
interface IntVar { 
  
  def int intValue()
  
  @Samplers(IntNaiveMHSampler)  
  static interface WritableIntVar extends IntVar {
    def void set(int value)
  }
  
  static class IntScalar implements WritableIntVar {
    
    var int value
    
    new(int value) { this.value = value }
    
    override int intValue() {
      return value
    }
    
    override void set(int newValue) {
      this.value = newValue
    }
    
    override String toString() {
      return Integer.toString(value)
    }
  }
}
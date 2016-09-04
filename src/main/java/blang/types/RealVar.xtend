package blang.types

import blang.mcmc.RealNaiveMHSampler
import blang.mcmc.Samplers

@FunctionalInterface
interface RealVar { 
  
  def double doubleValue()
  
  @Samplers(RealNaiveMHSampler)
  static class RealScalar implements RealVar { 
    
    var double value = 0.0
    
    new (double value) { this.value = value }
    
    override double doubleValue() {
      return value
    }
    
    def void set(double newValue) {
      this.value = newValue
    } 
    
    override String toString() {
      return Double.toString(value)
    }
  }
}
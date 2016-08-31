package blang.types

import blang.mcmc.Samplers
import blang.mcmc.RealNaiveMHSampler
import blang.inits.DesignatedConstructor
import blang.inits.Input
import blang.runtime.ObservationProcessor
import blang.inits.GlobalArg
import java.util.Optional

@FunctionalInterface
interface RealVar { 
  
  def double doubleValue()
  
  @Samplers(RealNaiveMHSampler)
  static class RealImpl implements RealVar {
    
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
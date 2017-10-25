package blang.types

import blang.mcmc.Samplers
import blang.core.WritableRealVar
import blang.mcmc.RealSliceSampler

@Samplers(RealSliceSampler)
class RealScalar implements WritableRealVar { 
  
  var double value = 0.0
  
  new (double value) { this.value = value }
  
  override double doubleValue() {
    return value
  }
  
  override void set(double newValue) {
    this.value = newValue
  } 
  
  override String toString() {
    return Double.toString(value)
  }
}
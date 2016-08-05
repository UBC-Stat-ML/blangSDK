package types

import blang.annotations.Samplers
import blang.mcmc.RealNaiveMHSampler

@Samplers(RealNaiveMHSampler)
class RealImplementation implements Real {
  
  var double value
  
  override double doubleValue() {
    return value
  }
  
  def void set(double newValue) {
    this.value = newValue
  }
  
}
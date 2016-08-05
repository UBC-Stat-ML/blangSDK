package types

import blang.annotations.Samplers
import blang.mcmc.IntNaiveMHSampler

@Samplers(IntNaiveMHSampler)
class IntImplementation implements Int {
  
  var int value
  
  override int intValue() {
    return value
  }
  
  def void set(int newValue) {
    this.value = newValue
  }
  
}
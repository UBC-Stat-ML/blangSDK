package blang.types

import blang.mcmc.Samplers
import blang.core.WritableIntVar
import blang.mcmc.IntSliceSampler

/** A latent integer random variable. */
@Samplers(IntSliceSampler) 
class IntScalar implements WritableIntVar {
  
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
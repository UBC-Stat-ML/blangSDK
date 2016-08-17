package blang.types

import blang.inits.Implementation
import blang.mcmc.Samplers
import blang.mcmc.RealNaiveMHSampler
import blang.inits.DesignatedConstructor
import java.util.List
import blang.inits.Input
import com.google.common.base.Joiner

@Implementation(RealImpl)
@FunctionalInterface
interface Real { 
  
  def double doubleValue()
  
  @Samplers(RealNaiveMHSampler)
  static class RealImpl implements Real {
    
    var double value
    
    @DesignatedConstructor
    new(@Input(formatDescription = "A real number") List<String> input) {
      value = Double.parseDouble(Joiner.on(" ").join(input))
    }
    
    override double doubleValue() {
      return value
    }
    
    def void set(double newValue) {
      this.value = newValue
    }
  }
}
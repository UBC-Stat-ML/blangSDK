package blang.types

import blang.inits.Implementation
import blang.mcmc.Samplers
import blang.mcmc.RealNaiveMHSampler
import blang.inits.DesignatedConstructor
import java.util.List
import blang.inits.Input
import com.google.common.base.Joiner
import blang.inits.ConstructorArg
import blang.runtime.ObservationProcessor

@Implementation(RealImpl)
@FunctionalInterface
interface RealVar { 
  
  def double doubleValue()
  
  @Samplers(RealNaiveMHSampler)
  static class RealImpl implements RealVar {
    
    var double value = 0.0
    
    new (double value) { this.value = value }
    
    @DesignatedConstructor
    def static RealImpl parse(
      @Input(formatDescription = "A real number") List<String> input,
      @ConstructorArg(ObservationProcessor::KEY) ObservationProcessor initContext
    ) {
      val String strValue = Joiner.on(" ").join(input).trim
      return
        if (strValue == NA::SYMBOL) {
          new RealImpl(0.0)
        } else {
          initContext.markAsObserved(new RealImpl(Double.parseDouble(strValue)))
        }
    }
    
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
package blang.types

import blang.inits.Implementation
import blang.inits.DesignatedConstructor
import java.util.List
import blang.inits.Input
import com.google.common.base.Joiner
import blang.inits.ConstructorArg
import blang.mcmc.Samplers
import blang.mcmc.BoolMHSampler
import blang.runtime.ObservationProcessor

@Implementation(BoolImpl)
@FunctionalInterface
interface BoolVar { 
  
  def boolean booleanValue()
  
  @Samplers(BoolMHSampler)    
  static class BoolImpl implements BoolVar {
    
    var boolean value
    
    new(boolean value) { this.value = value }
    
    @DesignatedConstructor
    def static BoolImpl parse(
      @Input(formatDescription = "true|false") List<String> input,
      @ConstructorArg(ObservationProcessor::KEY) ObservationProcessor initContext
    ) {
      val String strValue = Joiner.on(" ").join(input).trim
      return
        if (strValue == NA::SYMBOL) {
          new BoolImpl(false)
        } else {
          initContext.markAsObserved(new BoolImpl(
            if (strValue.toLowerCase == "true") {
              true
            } else if (strValue.toLowerCase == "false") {
              false
            } else {
              throw new RuntimeException("Invalid boolean string (should be 'true' or 'false'): " + strValue)
            }))
        }
    }
    
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
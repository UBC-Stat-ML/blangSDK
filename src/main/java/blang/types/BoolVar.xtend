package blang.types

import blang.inits.Implementation
import blang.inits.DesignatedConstructor
import java.util.List
import blang.inits.Input
import com.google.common.base.Joiner
import blang.inits.ConstructorArg
import blang.runtime.InitContext
import blang.mcmc.Samplers
import blang.mcmc.BoolMHSampler

@Implementation(BoolImpl)
@FunctionalInterface
interface BoolVar { 
  
  def boolean booleanValue()
  
  @Samplers(BoolMHSampler)    
  static class BoolImpl implements BoolVar {
    
    var boolean value
    
    @DesignatedConstructor
    new(
      @Input(formatDescription = "true|false") List<String> input,
      @ConstructorArg(InitContext::KEY) InitContext initContext
    ) {
      val String strValue = Joiner.on(" ").join(input).trim
      this.value =
        if (strValue == NA::SYMBOL) {
          initContext.markAsObserved(this, false)
          false
        } else {
          if (strValue.toLowerCase == "true") {
            true
          } else if (strValue.toLowerCase == "false") {
            false
          } else {
            throw new RuntimeException("Invalid boolean string (should be 'true' or 'false'): " + strValue)
          }
        }
    }
    
    override boolean booleanValue() {
      return value
    }
    
    def void set(boolean newValue) {
      this.value = newValue
    }
  }
}
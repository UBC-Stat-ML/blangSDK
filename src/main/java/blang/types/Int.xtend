package blang.types

import blang.inits.Implementation
import blang.inits.DesignatedConstructor
import java.util.List
import blang.inits.Input
import com.google.common.base.Joiner
import blang.inits.ConstructorArg
import blang.runtime.InitContext
import blang.mcmc.Samplers
import blang.mcmc.IntNaiveMHSampler

@Implementation(IntImpl)
@FunctionalInterface
interface Int { 
  
  def int intValue()
  
  @Samplers(IntNaiveMHSampler)    
  static class IntImpl implements Int {
    
    var int value
    
    @DesignatedConstructor
    new(
      @Input(formatDescription = "An integer") List<String> input,
      @ConstructorArg(InitContext::KEY) InitContext initContext
    ) {
      val String strValue = Joiner.on(" ").join(input).trim
      this.value =
        if (strValue == NA::SYMBOL) {
          initContext.markAsObserved(this, false)
          0
        } else {
          Integer.parseInt(strValue)
        }
    }
    
    override int intValue() {
      return value
    }
    
    def void set(int newValue) {
      this.value = newValue
    }
  }
}
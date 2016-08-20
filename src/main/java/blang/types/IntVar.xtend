package blang.types

import blang.inits.Implementation
import blang.inits.DesignatedConstructor
import java.util.List
import blang.inits.Input
import com.google.common.base.Joiner
import blang.inits.ConstructorArg
import blang.mcmc.Samplers
import blang.mcmc.IntNaiveMHSampler
import blang.runtime.ObservationProcessor

@Implementation(IntImpl)
@FunctionalInterface
interface IntVar { 
  
  def int intValue()
  
  @Samplers(IntNaiveMHSampler)   
  static class IntImpl implements IntVar {
    
    var int value
    
    new(int value) { this.value = value }
    
    @DesignatedConstructor
    def static IntImpl parse(
      @Input(formatDescription = "An integer") List<String> input,
      @ConstructorArg(ObservationProcessor::KEY) ObservationProcessor initContext
    ) {
      val String strValue = Joiner.on(" ").join(input).trim
      return
        if (strValue == NA::SYMBOL) {
          new IntImpl(0)
        } else {
          initContext.markAsObserved(new IntImpl(Integer.parseInt(strValue)))
        }
    }
    
    override int intValue() {
      return value
    }
    
    def void set(int newValue) {
      this.value = newValue
    }
    
    override String toString() {
      return Integer.toString(value)
    }
  }
}
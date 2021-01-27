package blang.types

import blang.core.RealVar
import blang.core.IntVar
import blang.types.StaticUtils

class SpikedRealVar implements RealVar {
  public val IntVar selected = StaticUtils::latentInt 
  public val RealVar continuousPart = StaticUtils::latentReal

  override doubleValue() {
    if (selected.intValue < 0 || selected.intValue > 1)
      StaticUtils::invalidParameter()
    if (selected.intValue == 0) return 0.0
    else return continuousPart.doubleValue
  }
  
  override toString() { "" + doubleValue }
}
package blang.types

import blang.core.RealVar

class AnnealingParameter implements RealVar { 
  var RealVar param = null
  
  def void _set(RealVar _param) {
    this.param = _param
  }
  
  override doubleValue() {
    return param.doubleValue
  }
  
}
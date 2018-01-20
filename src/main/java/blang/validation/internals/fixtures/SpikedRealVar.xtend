package blang.validation.internals.fixtures

import org.eclipse.xtend.lib.annotations.Data
import blang.core.RealVar

import java.util.List
import xlinear.Matrix
import blang.core.WritableRealVar
import blang.types.StaticUtils
import blang.core.WritableIntVar
import blang.mcmc.Samplers

@Data
@Samplers(SpikedRealVarSampler)
class SpikedRealVar implements RealVar {
  
  public val WritableRealVar realPart
  public val WritableIntVar isZero
  
  new() {
    realPart = StaticUtils::latentReal
    isZero = StaticUtils::latentInt 
  }
  
  override doubleValue() {
    if (isZero == 1) 0.0
    else realPart.doubleValue
  }
  
  def public static double *(List<SpikedRealVar> vars, Matrix vector){
    var sum = 0.0
    if (vars.size != vector.nEntries) {
      throw new RuntimeException
    }
    for (int i : 0 ..< vars.size) {
      sum += vector.get(i) * vars.get(i).doubleValue
    }
    return sum
  }
  
  override String toString() {
    return Double.toString(doubleValue) 
  }
}
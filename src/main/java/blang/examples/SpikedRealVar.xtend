package blang.examples

import org.eclipse.xtend.lib.annotations.Data
import blang.core.RealVar

import static extension blang.core.BlangExtensions.*
import blang.core.IntVar
import java.util.List
import xlinear.Matrix

@Data
class SpikedRealVar implements RealVar {
  
  public val RealVar realPart
  public val IntVar isZero
  
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
}
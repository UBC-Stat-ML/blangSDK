package blang.types

import blang.core.RealVar
import xlinear.Matrix
import bayonet.distributions.Random
import blang.runtime.internals.objectgraph.MatrixConstituentNode

class ExtensionUtils {  // Warning: blang.types.ExtensionUtils hard-coded in ca.ubc.stat.blang.scoping.BlangImplicitlyImportedFeatures
  
  def static RealVar getRealVar(Matrix m, int row, int col) {
    return new MatrixConstituentNode(m, row, col)
  }
  
  def static RealVar getRealVar(Matrix m, int index) {
    if (!m.isVector()) 
      throw xlinear.StaticUtils::notAVectorException
    if (m.nRows() == 1)
      return getRealVar(m, 0, index)
    else
      return getRealVar(m, index, 0)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
  
  /**
   * Convert into a Random object compatible with both 
   * Apache common's RandomGenerator and bayonet's 
   * Random.
   */
  def static Random generator(java.util.Random random) {
    if (random instanceof Random) {
      return random
    }
    return new Random(random)
  }
  
  def static void setTo(Matrix one, Matrix another) {
    if (one.nRows != another.nRows || one.nCols != another.nCols) {
      throw new RuntimeException
    }
    one *= 0.0
    one += another
  }
}
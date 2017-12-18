package blang.types

import blang.core.RealVar
import xlinear.Matrix
import bayonet.distributions.Random
import blang.runtime.internals.objectgraph.MatrixConstituentNode
import java.util.List
import blang.core.IntVar
import java.util.ArrayList

/** Automatically imported as extension methods, meaning functions f(a, b, ..) can be called as a.f(b, ...). */
class ExtensionUtils {  // Warning: blang.types.ExtensionUtils hard-coded in ca.ubc.stat.blang.scoping.BlangImplicitlyImportedFeatures
  
  /** View a single entry of a Matrix as a RealVar. */
  def static RealVar getRealVar(Matrix m, int row, int col) {
    return new MatrixConstituentNode(m, row, col)
  }
  
  /** View a single entry of a 1-by-n or n-by-1 Matrix as a RealVar. */
  def static RealVar getRealVar(Matrix m, int index) {
    if (!m.isVector()) 
      throw xlinear.StaticUtils::notAVectorException
    if (m.nRows() == 1)
      return getRealVar(m, 0, index)
    else
      return getRealVar(m, index, 0)
  }
  
  def static boolean asBool(int integer) {
    switch (integer) {
      case 0  : false
      case 1  : true
      default : throw new RuntimeException("Cannot cast to boolean: " + integer)
    }
  }
  
  def static int asInt(boolean bool) {
    if (bool) 1 else 0
  }
  
  def static boolean isBool(int integer) {
    return integer === 0 || integer === 1
  }
  
  def static boolean asBool(IntVar variable) {
    asBool(variable.intValue)
  }
  
  def static boolean isBool(IntVar variable) {
    isBool(variable.intValue)
  }
  
  def static <T> List<T> asList(Plated<T> plated, Plate<Integer> plate) {
    val List<T> result = new ArrayList()
    var int check = 0
    for (Index<Integer> index : plate.indices) {
      if (index.key != check++) {
        throw new RuntimeException("Assumes the plate is of the form 0, 1, 2, ..")
      }
      result.add(plated.get(index))
    }
    return result
  }
  
  /** Upgrade a java.util.Random into to the type of Random we use. */
  def static Random generator(java.util.Random random) {
    if (random instanceof Random) {
      return random
    }
    return new Random(random)
  }
  
  /** Copy the contents of a matrix into another one. */
  def static void setTo(Matrix one, Matrix another) {
    if (one.nRows != another.nRows || one.nCols != another.nCols) {
      throw new RuntimeException
    }
    one *= 0.0
    one += another
  }
  
  def static **(double base, double exp) {
    // a ** b has wrong operation priority in Xbase
    throw new RuntimeException("Not supported: use pow(base, exp)")
  }
  
  def static **(double base, int exp) {
    // a ** b has wrong operation priority in Xbase
    throw new RuntimeException("Not supported: use pow(base, exp)")
  }
  
  def static **(int base, int exp) {
    // a ** b has wrong operation priority in Xbase
    throw new RuntimeException("Not supported: use pow(base, exp)")
  }

}
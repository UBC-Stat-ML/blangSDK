package blang.types

import blang.core.RealVar
import xlinear.Matrix
import bayonet.distributions.Random
import blang.runtime.internals.objectgraph.MatrixConstituentNode
import java.util.List
import blang.core.IntVar
import java.util.ArrayList
import bayonet.math.NumericalUtils
import java.util.Map
import java.util.Collection
import java.util.LinkedHashMap

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
    return asList(plated, plate.indices)
  }
  def static <T> List<T> asList(Plated<T> plated, Collection<Index<Integer>> indices) {
    val List<T> result = new ArrayList()
    var int check = 0
    for (Index<Integer> index : indices) {
      if (index.key != check++) {
        throw new RuntimeException("Assumes the plate is of the form 0, 1, 2, ..")
      }
      result.add(plated.get(index))
    }
    return result
  }
  def static <T,K> Collection<T> asCollection(Plated<T> plated, Plate<K> plate) {
    return asCollection(plated, plate.indices) 
  }
  def static <T,K> Collection<T> asCollection(Plated<T> plated, Collection<Index<K>> indices) {
    val List<T> result = new ArrayList()
    for (Index<K> index : indices) {
      result.add(plated.get(index))
    }
    return result
  }
  def static <T,K> Map<K,T> asMap(Plated<T> plated, Plate<K> plate) {
    return asMap(plated, plate.indices) 
  }
  def static <T,K> Map<K,T> asMap(Plated<T> plated, Collection<Index<K>> indices) {
    val LinkedHashMap<K,T> result = new LinkedHashMap()
    for (Index<K> index : indices) {
      result.put(index.key, plated.get(index))
    }
    return result
  }
  
  /** Upgrade a java.util.Random into to the type of Random we use, bayonet.distributions.Random. */
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
  
  /**  */
  def static double sum(Iterable<? extends Number> numbers) {
    var sum = 0.0
    for (number : numbers) sum += number
    return sum
  }
  
  /** Increment an entry of a map to double, setting to the value if the key is missing. */
  def static <T> void increment(Map<T, Double> map, T key, double value) {
    val double old = map.get(key) ?: 0.0
    map.put(key, old + value)
  }
  
  /** Check if two numbers are within 1e-6 of each other. */
  def static boolean isClose(double n1, double n2) {
    if (n1 === Double.POSITIVE_INFINITY && n2 === Double.POSITIVE_INFINITY) return true
    if (n1 === Double.NEGATIVE_INFINITY && n2 === Double.NEGATIVE_INFINITY) return true
    return NumericalUtils.isClose(n1, n2, NumericalUtils::THRESHOLD) 
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
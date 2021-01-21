package blang.types

import blang.core.IntVar
import blang.core.RealVar
import java.util.ArrayList
import java.util.List
import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import blang.core.IntConstant
import blang.core.RealConstant
import bayonet.math.SpecialFunctions
import blang.types.internals.InvalidParameter
import blang.types.internals.RealScalar
import blang.types.internals.IntScalar
import blang.types.Precision.Diagonal
import blang.types.Precision.SimpleBrownian
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

/** Automatically statically imported in Blang meaning can call "StaticUtils::function(..)" as just "function(..)". */
class StaticUtils { // Warning: blang.types.StaticUtils hard-coded in ca.ubc.stat.blang.scoping.BlangImplicitlyImportedFeatures
  
  // Utilities for creating latent and fixed variables
  
  /** unobserved integer variable (initialized at zero). */
  def static IntScalar latentInt() {
    return new IntScalar(0)
  }
  
  /** unobserved real variable (represented in double precision, initialized at zero).  */
  def static RealScalar latentReal() {
    return new RealScalar(0.0)
  }
  
  /** unobserved real variable supporting a spike at zero (represented in double precision, initialized at zero).  */
  def static SpikedRealVar latentSpikedReal() {
    return new SpikedRealVar
  }
  
  /** fixed (constant or conditioned upon) integer scalar. */
  def static IntConstant fixedInt(int value) {
    return new IntConstant(value)
  }
  
  /** fixed real scalar. */
  def static RealConstant fixedReal(double value) {
    return new RealConstant(value)
  }
  
  /** size specifies the length of the list. */
  def static List<IntVar> latentIntList(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(blang.types.StaticUtils.latentInt)
    }
    return result
  }
  
  /** size specifies the length of the list. */
  def static List<RealVar> latentRealList(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(blang.types.StaticUtils.latentReal)
    }
    return result
  }
  
  /** size specifies the length of the list. */
  def static List<SpikedRealVar> latentSpikedRealList(int size) {
    val List<SpikedRealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(blang.types.StaticUtils.latentSpikedReal)
    }
    return result
  }
  
  /** list where the integer valued entries are fixed to the provided values. */
  def static List<IntVar> fixedIntList(int ... entries) {
    val List<IntVar> result = new ArrayList
    for (int entry : entries) {
      result.add(fixedInt(entry))
    }
    return result
  }
  
  def static List<RealVar> fixedRealList(double ... entries) {
    val List<RealVar> result = new ArrayList
    for (double entry : entries) {
      result.add(fixedReal(entry))
    }
    return result
  }
  
  /** an n-by-1 latent dense vector (initialized at zero). */
  def static DenseMatrix latentVector(int n) {
    return dense(n)
  }
  
  /** an n-by-1 fixed dense vector. */
  def static DenseMatrix fixedVector(double ... entries) {
    return denseCopy(entries).readOnlyView
  }
  
  /** an n-by-m latent dense matrix (initialized at zero). */
  def static DenseMatrix latentMatrix(int nRows, int nCols) {
    return dense(nRows, nCols)
  }
  
  /** a constant dense matrix. */
  def static DenseMatrix fixedMatrix(double [][] entries) {
    return denseCopy(entries).readOnlyView
  }
  
  /** latent n-by-1 matrix with entries summing to one (initialized at uniform). */
  def static DenseSimplex latentSimplex(int n) {
    val double unif = 1.0 / (n as double)
    val DenseMatrix m = dense(n)
    for (int index : 0 ..< n) {
      m.set(index, unif)
    }
    return new DenseSimplex(m)
  }
  
  /** creates a constant simplex, also checks the provided list of number sums to one. */
  def static DenseSimplex fixedSimplex(double ... probabilities) {
    return new DenseSimplex(denseCopy(probabilities).readOnlyView)
  }
  
  /** creates a constant simplex, also checks the provided vector sums to one. */
  def static DenseSimplex fixedSimplex(DenseMatrix probabilities) {
    return new DenseSimplex(probabilities.readOnlyView)
  }
  
  /** latent n-by-n matrix with rows summing to one. */
  def static DenseTransitionMatrix latentTransitionMatrix(int nStates) {
    val double unif = 1.0 / (nStates as double)
    val DenseMatrix m = dense(nStates, nStates)
    for (int r : 0 ..< nStates) {
      for (int c : 0 ..< nStates) {
        m.set(r, c, unif)
      }
    }
    return new DenseTransitionMatrix(m)
  }
  
  /** creates a constant transition matrix, also checks the provided rows all sum to one. */
  def static DenseTransitionMatrix fixedTransitionMatrix(DenseMatrix probabilities) {
    return new DenseTransitionMatrix(probabilities.readOnlyView)
  }
  
  /** creates a constant transition matrix, also checks the provided rows all sum to one. */
  def static DenseTransitionMatrix fixedTransitionMatrix(double [][] probabilities) {
    return new DenseTransitionMatrix(denseCopy(probabilities).readOnlyView)
  }

  def static double logFactorial(double input) {
    return SpecialFunctions.lnGamma(input+1);
  }

  def static double logBinomial(double n, double k) {
    return logFactorial(n) - logFactorial(k) - logFactorial(n-k);
  }
  
  def static double logGamma(double x) {
    return SpecialFunctions::lnGamma(x)
  }
  
  def static double logBeta(double x, double y) {
    return logGamma(x) + logGamma(y) - logGamma(x + y)
  }
  
  def static SummaryStatistics summaryStatistics(List<Double> values) {
    val result = new SummaryStatistics()
    for (double v : values) 
      result.addValue(v)
    return result 
  }
  
  def static SummaryStatistics summaryStatistics(double ... values) {
    val result = new SummaryStatistics()
    for (double v : values) 
      result.addValue(v)
    return result
  }
  
  def static <K> Diagonal<K> diagonalPrecision(RealVar diagonalPrecisionValue, Plate<K> plate) {
    return new Diagonal<K>(diagonalPrecisionValue, plate)
  }
  
  def static <K> SimpleBrownian simpleBrownian(RealVar sigma, Plate<Integer> plate) {
    return new SimpleBrownian(sigma, plate)
  }
  
  def static double NEGATIVE_INFINITY() {
    return Double.NEGATIVE_INFINITY
  }
  
  /*
   * Exception caught in ExponentiatedFactor.
   * 
   * Implementation note: does not record stack trace, so should not 
   * incur the full performance hit of exception throwing.
   * However this could still become the performance bottleneck. In such 
   * case, consider designing a sampler that avoid proposing invalid 
   * parameters as much as possible.
   */
  def static void invalidParameter() {
    throw InvalidParameter.instance;
  }
  
  private new() {}
}
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


/** Automatically statically imported in Blang meaning can call "StaticUtils::function(..)" as just "function(..)". */
class StaticUtils { // Warning: blang.types.StaticUtils hard-coded in ca.ubc.stat.blang.scoping.BlangImplicitlyImportedFeatures
  
  // Utilities for creating latent and constant variables
  
  def static IntScalar latentInt() {
    return new IntScalar(0)
  }
  
  def static RealScalar latentReal() {
    return new RealScalar(0.0)
  }
  
  def static IntConstant constantInt(int value) {
    return new IntConstant(value)
  }
  
  def static RealConstant constantReal(double value) {
    return new RealConstant(value)
  }
  
  def static List<IntVar> latentListOfInt(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(blang.types.StaticUtils.latentInt)
    }
    return new ArrayList(result)
  }
  
  def static List<RealVar> latentListOfReal(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(blang.types.StaticUtils.latentReal)
    }
    return new ArrayList(result)
  }
  
  def static DenseSimplex latentSimplex(int nStates) {
    val double unif = 1.0 / (nStates as double)
    val DenseMatrix m = dense(nStates)
    for (int index : 0 ..< nStates) {
      m.set(index, unif)
    }
    return new DenseSimplex(m)
  }
  
  def static DenseSimplex constantSimplex(double ... probabilities) {
    return new DenseSimplex(denseCopy(probabilities).readOnlyView)
  }
  
  def static DenseSimplex constantSimplex(DenseMatrix probabilities) {
    return new DenseSimplex(probabilities.readOnlyView)
  }
  
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
  
  def static DenseTransitionMatrix constantTransitionMatrix(DenseMatrix probabilities) {
    return new DenseTransitionMatrix(probabilities.readOnlyView)
  }
  
  def static DenseTransitionMatrix constantTransitionMatrix(double [][] probabilities) {
    return new DenseTransitionMatrix(denseCopy(probabilities).readOnlyView)
  }

  def static double logFactorial(double input) 
  {
    return SpecialFunctions.lnGamma(input+1);
  }

  def static double logBinomial(double n, double k)
  {
    return logFactorial(n) - logFactorial(k) - logFactorial(n-k);
  }
  
  def static double NEGATIVE_INFINITY() {
    Double.NEGATIVE_INFINITY
  }
  
  /**
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
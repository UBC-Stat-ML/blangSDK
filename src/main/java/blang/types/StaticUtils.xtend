package blang.types

import blang.core.IntVar
import blang.core.RealVar
import java.util.ArrayList
import java.util.List
import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import blang.core.IntConstant
import blang.core.RealConstant
import org.apache.commons.math3.special.Gamma
import bayonet.math.SpecialFunctions

class StaticUtils { // Warning: blang.types.StaticUtils hard-coded in ca.ubc.stat.blang.scoping.BlangImplicitlyImportedFeatures
  
  //// Initialization utilities
  
  def static IntScalar intVar() {
    return intVar(Integer::MIN_VALUE)
  }
  
  def static RealScalar realVar() {
    return realVar(Double::NaN)
  }
  
  def static IntScalar intVar(int initialValue) {
    return new IntScalar(initialValue)
  }
  
  def static RealScalar realVar(double initialValue) {
    return new RealScalar(initialValue)
  }
  
  def static IntConstant constant(int value) {
    return new IntConstant(value)
  }
  
  def static RealConstant constant(double value) {
    return new RealConstant(value)
  }
  
  def static List<IntVar> listOfIntVars(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(intVar(0))
    }
    return new ArrayList(result)
  }
  
  def static List<RealVar> listOfRealVars(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(realVar(0.0))
    }
    return new ArrayList(result)
  }
  
  def static DenseSimplex denseSimplex(int nStates) {
    val double unif = 1.0 / (nStates as double)
    val DenseMatrix m = dense(nStates)
    for (int index : 0 ..< nStates) {
      m.set(index, unif)
    }
    return StaticUtils.denseSimplex(m)
  }
  
  def static DenseSimplex denseSimplex(DenseMatrix m) {
    return new DenseSimplex(m)
  }
  
  def static DenseSimplex denseSimplex(double [] probabilities) {
    return StaticUtils.denseSimplex(denseCopy(probabilities))
  }
  
  def static DenseTransitionMatrix transitionMatrix(int nStates) {
    val double unif = 1.0 / (nStates as double)
    val DenseMatrix m = dense(nStates, nStates)
    for (int r : 0 ..< nStates) {
      for (int c : 0 ..< nStates) {
        m.set(r, c, unif)
      }
    }
    return StaticUtils.denseTransitionMatrix(m)
  }
  
  def static DenseTransitionMatrix denseTransitionMatrix(DenseMatrix m) {
    return new DenseTransitionMatrix(m)
  }
  
  def static DenseTransitionMatrix denseTransitionMatrix(double [][] probabilities) {
    return StaticUtils.denseTransitionMatrix(denseCopy(probabilities))
  }
  
  /**
   * An assertion check that is always performed.
   */
  def static void check(boolean condition) {
    if (!condition) {
      throw new RuntimeException("Assertion violated")
    }
  }

  def static double logFactorial(double input) 
  {
    return SpecialFunctions.lnGamma(input+1);
  }

  def static double logBinomial(double n, double k)
  {
    return logFactorial(n) - logFactorial(k) - logFactorial(n-k);
  }
  
  private new() {}
}
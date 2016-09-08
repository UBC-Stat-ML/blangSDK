package blang.utils

import java.util.List
import java.util.ArrayList
import blang.types.Simplex
import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils
import blang.types.TransitionMatrix
import blang.types.RealVar
import blang.types.RealVar.RealScalar
import blang.types.IntVar
import blang.types.IntVar.IntScalar
import java.util.Collections

class StaticUtils {
  
  //// Initialization utilities
  
    // TODO: rename
  def static RealVar createLatentReal(double initialValue) { 
    return new RealScalar(initialValue)
  }
  
  def static IntVar createLatentInt(int initialValue) { 
    return new IntScalar(initialValue)
  }
  
  // TODO: rename?
  def static List<IntVar> listOfIntVars(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(createLatentInt(0))
    }
    return Collections::unmodifiableList(result)
  }
  
  def static List<RealVar> listOfRealVars(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(createLatentReal(0.0))
    }
    return Collections::unmodifiableList(result)
  }
  
  
  def static Simplex simplex(int nStates) {
    val double unif = 1.0 / (nStates as double)
    val DenseMatrix m = dense(nStates)
    for (int index : 0 ..< nStates) {
      m.set(index, unif)
    }
    return simplex(m)
  }
  
  def static Simplex simplex(DenseMatrix m) {
    NumericalUtils::checkIsClose(m.sum, 1.0)
    return new Simplex(m)
  }
  
  def static Simplex simplex(double [] probabilities) {
    return simplex(denseCopy(probabilities))
  }
  
  def static TransitionMatrix transitionMatrix(int nStates) {
    val double unif = 1.0 / (nStates as double)
    val DenseMatrix m = dense(nStates, nStates)
    for (int r : 0 ..< nStates) {
      for (int c : 0 ..< nStates) {
        m.set(r, c, unif)
      }
    }
    return transitionMatrix(m)
  }
  
  def static TransitionMatrix transitionMatrix(DenseMatrix m) {
    NumericalUtils::checkIsTransitionMatrix(toArray(m))
    return new TransitionMatrix(m)
  }
  
  def static TransitionMatrix transitionMatrix(double [][] probabilities) {
    return transitionMatrix(denseCopy(probabilities))
  }

  //// mathematical functions
  
  def static double logistic(double value) {
    return 1.0 / (1.0 + Math.exp(-value))
  }

  private new() {}
}
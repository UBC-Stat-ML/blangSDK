package blang.utils

import java.util.List
import java.util.ArrayList
import blang.types.Simplex
import xlinear.DenseMatrix

import static xlinear.MatrixOperations.*
import static extension xlinear.MatrixExtensions.*
import bayonet.math.NumericalUtils
import blang.types.TransitionMatrix
import blang.core.RealVar
import blang.types.RealScalar
import blang.core.IntVar
import blang.types.IntScalar
import java.util.Collections

class StaticUtils {
  
  //// Initialization utilities
  
  def static IntVar intVar(int initialValue) {
    return new IntScalar(initialValue)
  }
  
  def static RealVar realVar(double initialValue) {
    return new RealScalar(initialValue)
  }
  
  def static List<IntVar> listOfIntVars(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(intVar(0))
    }
    return Collections::unmodifiableList(result)
  }
  
  def static List<RealVar> listOfRealVars(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(realVar(0.0))
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
  


  private new() {}
}
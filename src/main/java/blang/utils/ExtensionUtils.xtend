package blang.utils

import blang.types.IntVar
import java.util.List
import blang.types.RealVar
import java.util.ArrayList
import blang.types.IntVar.IntScalar
import blang.types.RealVar.RealScalar
import xlinear.Matrix
import blang.types.RealVar.RealMatrixComponent
import blang.types.Simplex
import xlinear.DenseMatrix
import static extension xlinear.MatrixOperations.*
import blang.types.TransitionMatrix
import bayonet.math.NumericalUtils
import java.util.Collections

class ExtensionUtils {
  
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
    NumericalUtils::checkIsTransitionMatrix(m.toArray)
    return new TransitionMatrix(m)
  }
  
  def static TransitionMatrix transitionMatrix(double [][] probabilities) {
    return transitionMatrix(denseCopy(probabilities))
  }
  
  def static RealVar getRealVar(Matrix m, int row, int col) {
    return new RealMatrixComponent(row, col, m)
  }
  
  def static RealVar getRealVar(Matrix m, int index) {
    if (!m.isVector()) 
      throw xlinear.StaticUtils::notAVectorException
    if (m.nRows() == 1)
      return getRealVar(m, 0, index)
    else
      return getRealVar(m, index, 0)
  }
  
  def static RealVar createLatentReal(double initialValue) { 
    return new RealScalar(initialValue)
  }
  
  def static IntVar createLatentInt(int initialValue) { 
    return new IntScalar(initialValue)
  }
  
  def static RealVar createConstantReal(double value) {
    return [value]
  }
  
  def static IntVar createConstantInt(int value) {
    return [value]
  }
  
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
  
  def static <T> T get(List<T> list, IntVar intVar) {
    return list.get(intVar.intValue)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
}
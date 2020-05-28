package blang.engines.internals

import org.apache.commons.math3.analysis.differentiation.DerivativeStructure
import xlinear.MatrixOperations
import xlinear.DenseMatrix

class MathCommonsAutoDiff {
  
  def static DenseMatrix gradient(DerivativeStructure structure) {
    val p = structure.freeParameters
    val result = MatrixOperations::dense(p)
    val indices = newIntArrayOfSize(p)
    for (i : 0 ..< p) {
      if (i > 0) indices.set(i-1,0)
      indices.set(i, 1)
      result.set(i, structure.getPartialDerivative(indices)) 
    }
    return result
  }
  
  def static DerivativeStructure *(Number a, DerivativeStructure x) {
    return x.multiply(a.doubleValue) 
  }
  
  def static DerivativeStructure *(DerivativeStructure x, DerivativeStructure y) {
    return x.multiply(y) 
  }
  
  def static DerivativeStructure *(DerivativeStructure x, Number a) {
    return x.multiply(a.doubleValue)
  }
  
  def static DerivativeStructure +(DerivativeStructure x, DerivativeStructure y) {
    return x.add(y) 
  }
  
  def static DerivativeStructure +(Number a, DerivativeStructure x) {
    return x.add(a.doubleValue) 
  }
  
  def static DerivativeStructure +(DerivativeStructure x, Number a) {
    return x.add(a.doubleValue) 
  }
  
  def static DerivativeStructure -(DerivativeStructure x, DerivativeStructure y) {
    return x.add(y.negate)
  }
  
  def static DerivativeStructure -(DerivativeStructure x, Number a) {
    return x.add(-a.doubleValue)
  }
  
  def static DerivativeStructure -(Number a, DerivativeStructure x) {
    return x.negate.add(a.doubleValue)
  }
  
  def static DerivativeStructure /(DerivativeStructure x, DerivativeStructure y) {
    return x.divide(y)
  }
  
  def static DerivativeStructure /(DerivativeStructure x, Number a) {
    return x.divide(a.doubleValue)
  }
  
  def static DerivativeStructure /(Number a, DerivativeStructure y) {
    y.reciprocal.multiply(a.doubleValue)
  }
}
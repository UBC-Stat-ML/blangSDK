package blang.engines.internals

import blang.engines.internals.Spline.MonotoneCubicSpline
import org.apache.commons.math3.analysis.differentiation.DerivativeStructure

class SplineDerivatives {
  
  def static double derivative(MonotoneCubicSpline it, double _x) {
     val n = mX.length
     if (Double.isNaN(_x)) {
       return _x;
     }
     if (_x <= mX.get(0)) {
       return 0.0
     }
     if (_x >= mX.get(n - 1)) {
         return 0.0
     }
     // Find the index 'i' of the last point with smaller X.
     // We know this will be within the spline due to the boundary tests.
     var i = 0;
     while (_x >= mX.get(i + 1)) {
         i += 1
//         if (_x == mX.get(i)) {
//             return mY.get(i)
//         }
     }
     val h = mX.get(i + 1) - mX.get(i)
     val x = new DerivativeStructure(1, 1, 0, _x)
     val t = (x - mX.get(i)) / h
     val result = (mY.get(i) * (1 + 2 * t) + h * mM.get(i) * t) * (1 - t) * (1 - t) + 
        (mY.get(i + 1) * (3 - 2 * t) + h * mM.get(i + 1) * (t - 1)) * t * t 
     return result.getPartialDerivative(1)
  }
  
  def static DerivativeStructure *(Number a, DerivativeStructure x) {
    return x.multiply(a.doubleValue) 
  }
  
  def static DerivativeStructure *(DerivativeStructure x, DerivativeStructure y) {
    return x.multiply(y) 
  }
  
  def static DerivativeStructure +(DerivativeStructure x, DerivativeStructure y) {
    return x.add(y) 
  }
  
  def static DerivativeStructure +(Number a, DerivativeStructure x) {
    return x.add(a.doubleValue) 
  }
  
  def static DerivativeStructure -(DerivativeStructure x, Number a) {
    return x.add(-a.doubleValue)
  }
  
  def static DerivativeStructure -(Number a, DerivativeStructure x) {
    return x.negate.add(a.doubleValue)
  }
  
  def static DerivativeStructure /(DerivativeStructure x, Number a) {
    return x.divide(a.doubleValue)
  }
}
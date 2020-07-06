package blang.engines.internals;

import bayonet.math.NumericalUtils;

/**
 * Stores a sum in log scale and allow adding 
 * one term stored in log scale
 */
public class LogSumAccumulator {
  double logSum = Double.NEGATIVE_INFINITY;
  long n = 0;
  
  public double logSum() {
    return logSum;
  }
  
  public long numberOfTerms() {
    return n;
  }
  
  /**
   * Conceptually, performs logSum <- log ( exp(logSum) + exp(logTerm) )
   * but in a numerically stable and efficient fashion.
   * 
   * @param logTerm
   */
  public void add(double logTerm) {
    logSum = NumericalUtils.logAdd(logSum, logTerm);
    n++;
  }
}

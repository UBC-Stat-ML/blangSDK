package blang.mcmc;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import blang.core.LogScaleFactor;
import blang.core.SupportFactor;
import briefj.BriefLog;

/**
 * Compute the product of several factors, taking care of some 
 * details such as:
 * 
 * 1- fact that support should be checked first since they can 
 *    take an absorbing value state of -INFINITY
 * 2- if one support factor throws an exception, it may still be 
 *    ok if there is at least another one with value -INFINITY
 * 3- reordering the list so that 2 does not occur too often. 
 */
public class FactorProduct {

  private final List<SupportFactor> supportFactors;
  private final List<LogScaleFactor> numericFactors;
  private boolean shuffleOccurred = false;
  
  public FactorProduct(List<SupportFactor> supportFactors, List<LogScaleFactor> numericFactors) {
    super();
    this.supportFactors = new ArrayList<>(supportFactors);
    this.numericFactors = numericFactors;
  }
  
  public double logDensity() {
    RuntimeException firstException = null;
    for (SupportFactor support : supportFactors) {
      try {
        if (!support.isInSupport()) {
          if (firstException != null) {
            // recovered from exception
            // but perhaps can avoid to pay the cost 
            // of throwing exception for future calls
            optimizeSupportsOrder(support);
          }
          // -INFINITY is absorbing so don't have to 
          // query the other factors
          return Double.NEGATIVE_INFINITY;
        }
      } catch (RuntimeException e) {
        // don't throw it yet, might be ok if some other 
        // support factor deem this state invalid anyways
        firstException = e;
      }
    }
    if (firstException != null) {
      throw firstException;
    }
    
    double sum = 0.0;
    for (LogScaleFactor numericFactor : numericFactors)
      sum += numericFactor.logDensity();
    
    return sum;
  }

  private void optimizeSupportsOrder(SupportFactor support) {
    if (shuffleOccurred) {
      BriefLog.warnOnce("Potential performance issue: please enter a github issue "
          + "called 'Model found justifying better heuristic in FactorProduct.optimizeSupportsOrder()'");
      return;
    }
    Collections.swap(supportFactors, 0, supportFactors.indexOf(support)); 
    shuffleOccurred = true;
  }
  
}

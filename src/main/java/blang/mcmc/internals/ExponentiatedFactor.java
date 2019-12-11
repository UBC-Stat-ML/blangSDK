package blang.mcmc.internals;

import blang.core.AnnealedFactor;
import blang.core.LogScaleFactor;
import blang.core.RealVar;
import blang.runtime.internals.objectgraph.SkipDependency;
import blang.types.internals.InvalidParameter;


public class ExponentiatedFactor implements AnnealedFactor
{
  private final LogScaleFactor enclosed;
  public final boolean treatNaNAsNegativeInfinity; 
  public final boolean annealSupport;
  
  /**
   * Compute the density of the enclosed density.
   * Catch exceptions of type InvalidParameter 
   * (thrown by calling StaticUtils.invalidParameter()) 
   * and return negative infinity in such case.
   */
  public double enclosedLogDensity()
  {
    try { 
      double result = enclosed.logDensity();
      if (Double.isNaN(result)) {
        if (treatNaNAsNegativeInfinity) return Double.NEGATIVE_INFINITY;
        throw new RuntimeException("Factors should not return NaN. Use NEGATIVE_INFINITY to forbid configurations. If you are sure this NaN is OK, you can use the option 'treatNaNAsNegativeInfinity'. Caused by: " + enclosed.getClass().getCanonicalName() + "; code: " + enclosed);
      }
      return result; 
    } 
    catch (InvalidParameter ip) { return Double.NEGATIVE_INFINITY; }
  }
  
  /*
   * Note: we are using a RealVar here to allow O(1) 
   * updates of the annealing parameter of large factor graph.
   * 
   * If null, use exponent = 1
   */
  @SkipDependency(isMutable = false)
  private RealVar exponent = null;
  
  /*
   * Notes: thoughts about potential DSL-based alternate impl
   * - first, wait to have one or two convincing use cases,
   *     probably custom samplers, maybe a big data thing.
   * - do not change exponent into a more complex type (e.g 
   *     one storing (i, N) rep of i/N since those would not 
   *     apply for adaptive Jaryinski for example
   * - use exponent as a special param, needs to be excluded 
   *     from builder and constructor, setter instead of a 
   *     supplier; check unicity
   * - Note: would need to adjust line search to start conservative 
   *     when using custom, compute sensitive implementations
   * - Not great idea to use custom implementations for say conjugacy
   *     since potential sampler gains might be off-set by higher 
   *     cost of computing SampledModel.logDensityRatio .. 
   */
  
  public ExponentiatedFactor(LogScaleFactor enclosed, boolean treatNaNAsNegativeInfinity, boolean annealSupport)
  {
    this.annealSupport = annealSupport;
    this.treatNaNAsNegativeInfinity = treatNaNAsNegativeInfinity;
    if (enclosed instanceof AnnealedFactor) 
      throw new RuntimeException("Trying to anneal a factor which is already annealed.");
    this.enclosed = enclosed;
  }

  @Override
  public double logDensity()
  {
    double expValue = getExponentValue();
    if (expValue == 0.0)
      return 0.0;
    double enclosedLogDensity = enclosedLogDensity();
    if (enclosedLogDensity == Double.NEGATIVE_INFINITY && annealSupport)
      return annealedMinusInfinity(expValue);  
    return expValue * enclosedLogDensity;
  }
  
  public static double annealedMinusInfinity(double exponent) 
  {
    if (exponent >= 1.0)
      return Double.NEGATIVE_INFINITY;
    return - exponent * 1E100; 
  }
  
  public double getExponentValue() 
  {
    if (exponent == null)
      return 1.0;
    else 
      return exponent.doubleValue();
  }

  @Override
  public RealVar getAnnealingParameter() 
  {
    return exponent;
  }

  @Override
  public void setAnnealingParameter(RealVar param) 
  {
    this.exponent = param;
  }
}

package blang.mcmc.internals;

import blang.core.AnnealedFactor;
import blang.core.LogScaleFactor;
import blang.core.RealVar;
import blang.runtime.internals.objectgraph.SkipDependency;


public class ExponentiatedFactor implements AnnealedFactor
{
  public final LogScaleFactor enclosed;
  
  /*
   * Note: we are using a RealVar here to allow O(1) 
   * updates of the annealing parameter of large factor graph.
   * 
   * If null, use exponent = 1
   */
  @SkipDependency 
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
  
  public ExponentiatedFactor(LogScaleFactor enclosed)
  {
    if (enclosed instanceof AnnealedFactor) 
      throw new RuntimeException("Trying to anneal a factor which is already annealed.");
    this.enclosed = enclosed;
  }

  @Override
  public double logDensity()
  {
    double enclosedLogDensity = enclosed.logDensity();
    double expValue = getExponentValue();
    if (enclosedLogDensity == Double.NEGATIVE_INFINITY)
      return annealedMinusInfinity(expValue);  
    return expValue * enclosedLogDensity;
  }
  
  /**
   * @return -INF if exponent is one, o.w., - (0.5 + 0.5 * exponent) * 1E100
   * 
   * RATIONALE: during annealing (exp < 1), we want to strongly discourage hard constraint 
   * violation, but setting gamma to -INF prevents us from e.g. comparing particles with 
   * different numbers of violation in cases where all particles violate some constraints. 
   * 
   * At the same time, even in early generations, if there is at least one particle with 
   * no constraint violation its probability should overwhelm all the violating ones 
   * (this is important e.g. in cases where constraint violation would otherwise break 
   * the user's likelihood evaluation code (out of bound errors on random indices, etc).
   * 
   * The penalty should also increase so that incremental weight updates in e.g. SMC Sampler
   * algorithms pick up the penalty. i.e. there will be used as:
   * 
   * pi_n(x) / pi_{n-1}(x) = exp{ # violations * [ - (0.5 + 0.5 * T2) * Double.MAX_VALUE + (0.5 + 0.5 * T1) * Double.MAX_VALUE ] }
   * 
   * where T1, T2 \in [0, 1] will be values in the typical range Ti \in 0.0001-0.1
   * 
   * We pick 1E100 rather than Double.MAX_VALUE to cover cases where say thousands or more 
   * constraints are initially violated.
   * 
   * We also want the extreme case exp = 0 to penalize constraints, e.g. if we do MCMC move 
   * in parallel tempering with some chains at temperature t = 0.
   */
  public static double annealedMinusInfinity(double exponent) 
  {
    if (exponent == 1.0)
      return Double.NEGATIVE_INFINITY;
    return - (0.5 + 0.5 * exponent) * 1E100; 
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

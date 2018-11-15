package blang.distributions;

import org.apache.commons.math3.distribution.BetaDistribution;
import org.apache.commons.math3.distribution.BinomialDistribution;
import org.apache.commons.math3.distribution.ChiSquaredDistribution;
import org.apache.commons.math3.distribution.GammaDistribution;
import org.apache.commons.math3.distribution.GeometricDistribution;
import org.apache.commons.math3.distribution.PoissonDistribution;
import org.apache.commons.math3.distribution.TDistribution;

import bayonet.math.NumericalUtils;
import blang.types.DenseSimplex;
import blang.types.internals.Delegator;
import briefj.collections.UnorderedPair;
import xlinear.CholeskyDecomposition;
import xlinear.DenseMatrix;
import xlinear.Matrix;
import xlinear.MatrixOperations;

import static blang.types.ExtensionUtils.generator;

import java.util.Random;

/** Various random number generators. */
public class Generators // Warning: blang.distributions.Generators hard-coded in ca.ubc.stat.blang.scoping.BlangImplicitlyImportedFeatures 
{
  /** */
  public static double halfstudentt(Random random, double nu, double sigma) {
	  double t = studentt(random, nu);
	  return Math.abs(t) * sigma;
  }
  
  /** */
  public static int geometric(Random random, double prob)
  {
    int result = new GeometricDistribution(generator(random), prob).sample();
    if (result == 0.0) // avoid crash-inducing zero probability corner cases
       result = (int) ZERO_PLUS_EPS;
    return result;
  }
  
  /** */
  public static double chisquared(Random random, int nu)
  {
	double result = new ChiSquaredDistribution(generator(random), (double) nu).sample();
	if (result == 0.0) // avoid crash-inducing zero probability corner cases
	  result = ZERO_PLUS_EPS;
	return result;
  }
  
  /** */
  public static double studentt(Random random, double nu)
  {
	  return new TDistribution(generator(random), nu).sample();
  }
	
  /** */
  public static double gamma(Random random, double shape, double rate)
  {
    double result = new GammaDistribution(generator(random), shape, 1.0/rate).sample();
    if (result == 0.0) // avoid crash-inducing zero probability corner cases
      result = ZERO_PLUS_EPS;
    return result;
  }

  /** */
  public static double beta(Random random, double alpha, double beta)
  {
    double result = 
        new BetaDistribution(generator(random), alpha, beta).sample();
    if (result == 0.0) // avoid crash-inducing zero probability corner cases
      result = ZERO_PLUS_EPS;
    if (result == 1.0)
      result = ONE_MINUS_EPS;
    return result;
  }
  
  /** */
  public static boolean bernoulli(Random random, double p) 
  {
    if (random instanceof bayonet.distributions.Random)
      return ((bayonet.distributions.Random) random).nextBernoulli(p);
    return bayonet.distributions.Random.nextBernoulli(random, p);
  }
  
  /** */
  public static int categorical(Random random, double [] probabilities)
  {
    if (random instanceof bayonet.distributions.Random)
      return ((bayonet.distributions.Random) random).nextCategorical(probabilities);
    return bayonet.distributions.Random.nextCategorical(random, probabilities);
  }
  
  /** */
  public static int binomial(Random random, int numberOfTrials, double probabilityOfSuccess)
  {
    return new BinomialDistribution(generator(random), numberOfTrials, probabilityOfSuccess).sample();
  }
  
  /** */
  public static int negativeBinomial(Random random, double r, double p) 
  {
    // Use Gamma-Poisson mixture
    double lambda = gamma(random, r, (1-p) / p);
    return poisson(random, lambda);
  }
  
  /** */
  public static double unitRateExponential(Random random)
  {
    return - Math.log(random.nextDouble());
  }
  
  /** */
  public static double exponential(Random random, double rate)
  {
    return unitRateExponential(random) / rate;
  }
  
  /** */
  public static double uniform(Random random, double min, double max)
  {
    if (max < min)
      throw new RuntimeException("Invalid arguments " + min + ", " + max);
    return min + random.nextDouble() * (max - min);
  }
  
  /** */
  public static int discreteUniform(Random rand, int minInclusive, int maxExclusive)
  {
    if (maxExclusive <= minInclusive)
      throw new RuntimeException("Invalid arguments " + minInclusive + ", " + maxExclusive);
    int range = maxExclusive - minInclusive;
    if (range > 0) 
      return rand.nextInt(range) + minInclusive;
    else // even with above check, this can still happen because of overflows (e.g. in test of commit 9a0250d267e2be7eb4d53af09a362733caf5543e)
    {
      // discretize the continuous uniform since nextLong(max) not available
      int result = (int) uniform(rand, minInclusive, maxExclusive);
      if (result < minInclusive)
        result = minInclusive;
      if (result >= maxExclusive)
        result = maxExclusive - 1;
      return result;
    }
  }
  
  /** */
  public static DenseSimplex dirichlet(Random random, Matrix concentrations) 
  {
    DenseMatrix result = MatrixOperations.dense(concentrations.nEntries());
    dirichletInPlace(random, concentrations, result);
    return new DenseSimplex(result);
  }
  
  @SuppressWarnings("unchecked")
  static void dirichletInPlace(Random random, Matrix concentrations, Matrix result)
  {
    if (result instanceof Delegator<?>)
      result = ((Delegator<Matrix>) result).getDelegate();
    if (concentrations.nonZeroEntries().min().getAsDouble() < 1) 
    {
      // This sub-case based on a trick in Stan's code 
      // see https://groups.google.com/forum/#!msg/stan-users/Q1ZDhlGPZyc/AVuX_7pEdSsJ
      double [] array = new double[concentrations.nEntries()];
      for (int d = 0; d < concentrations.nEntries(); d++)
      {
        double gammaVariate = gamma(random, concentrations.get(d) + 1.0, 1.0);
        double logU = Math.log(random.nextDouble());
        array[d] = Math.log(gammaVariate) + logU / concentrations.get(d);
      }
      double logSumExp = NumericalUtils.logAdd(array);
      for (int d = 0; d < concentrations.nEntries(); d++)
        result.set(d, Math.exp(array[d] - logSumExp));
    }
    else
    {
      double sum = 0.0;
      for (int d = 0; d < concentrations.nEntries(); d++)
      {
        double gammaVariate = gamma(random, concentrations.get(d), 1e7);
        result.set(d, gammaVariate);
        sum += gammaVariate;
      }
      result.divInPlace(sum);
    }
    for (int d = 0; d < concentrations.nEntries(); d++)
    {
      if (result.get(d) == 0.0) // avoid crash-inducing zero probability corner cases
        result.set(d, ZERO_PLUS_EPS);
      else if (result.get(d) == 1.0)
        result.set(d, ONE_MINUS_EPS);
      if (!(result.get(d) > 0.0 && result.get(d) < 1.0))
        throw new RuntimeException();
    }
  }
  
  /** */
  public static Matrix multivariateNormal(Random rand, Matrix mean, CholeskyDecomposition precision) 
  {
    return MatrixOperations.sampleNormalByPrecision(rand, precision).add(mean);
  }
  
  /** */
  public static Matrix standardMultivariateNormal(Random rand, int dim)
  {
    return MatrixOperations.sampleStandardNormal(rand, dim);
  }
  
  /** */
  public static double normal(Random rand, double mean, double variance)
  {
    return rand.nextGaussian() * Math.sqrt(variance) + mean;
  }
  
  /** */
  public static double standardNormal(Random rand) 
  {
    return rand.nextGaussian();
  }
  
  /** */
  public static int poisson(Random rand, double mean) 
  {
    return new PoissonDistribution(generator(rand), mean, PoissonDistribution.DEFAULT_EPSILON, PoissonDistribution.DEFAULT_MAX_ITERATIONS).sample();
  }
  
  public static UnorderedPair<Integer,Integer> distinctPair(Random rand, int listSize)
  {
    if (listSize < 2) 
      throw new RuntimeException("Sampling a distinct pair only defined for list of size at least two.");
    int first = rand.nextInt(listSize);
    int _second = rand.nextInt(listSize - 1);
    int second = _second + (_second < first ? 0 : 1);
    return UnorderedPair.of(first, second);
  }
  
  public static final double ZERO_PLUS_EPS = 1e-300;
  public static final double ONE_MINUS_EPS = 1.0 - 1e-16;

  private Generators() {}
}

package blang.distributions;

import org.apache.commons.math3.distribution.BetaDistribution;
import org.apache.commons.math3.distribution.BinomialDistribution;
import org.apache.commons.math3.distribution.ChiSquaredDistribution;
import org.apache.commons.math3.distribution.FDistribution;
import org.apache.commons.math3.distribution.GammaDistribution;
import org.apache.commons.math3.distribution.GeometricDistribution;
import org.apache.commons.math3.distribution.GumbelDistribution;
import org.apache.commons.math3.distribution.HypergeometricDistribution;
import org.apache.commons.math3.distribution.LaplaceDistribution;
import org.apache.commons.math3.distribution.LogisticDistribution;
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
    public static int betaBinomial(Random random, double alpha, double beta, int numberOfTrials)
    {
        double x = beta(random, alpha, beta);
        int y = binomial(random,numberOfTrials,x);
        return y;
    }
    
    /** */
    public static int hyperGeometric(Random random, int numberOfDraws, int population, int populationConditioned)
    {
        int result = new HypergeometricDistribution(generator(random), population, populationConditioned, numberOfDraws).sample();
        return result;
    }
    
    /** */
  public static double gompertz(Random rand, double shape, double scale)
  {
    double percentile = rand.nextDouble();
    double result = scale * Math.log(1 - (1 / shape)*Math.log(1-percentile));
    if (result == 0.0)
    		result = ZERO_PLUS_EPS;
    return result;
  }
  
  /** */
  public static double gumbel(Random rand, double location, double scale)
  {
    double result = new GumbelDistribution(generator(rand), location, scale).sample();
    if (result == 0.0) 
    		result = ZERO_PLUS_EPS;
    return result;
  }
  
  /** */
  public static double weibull(Random rand, double scale, double shape)
  {
    double percentile = rand.nextDouble();
    double result = scale*Math.pow(-Math.log(1 - percentile), (1/shape));
    if (result == 0.0)
    		result = ZERO_PLUS_EPS;
    return result;
  }
  
  /** */
  public static double fDist(Random rand, double d1, double d2) 
  {
	double result = new FDistribution(generator(rand), d1, d2).sample();
	if (result == 0.0)
		result = ZERO_PLUS_EPS;
	return result;
  }
  
  /** */
  public static double logisticDist(Random rand, double location, double scale) 
  {
	return new LogisticDistribution(generator(rand), location, scale).sample();
  }
  
  /** */
  public static double logLogistic(Random rand, double scale, double shape)
  {
	double percentile = rand.nextDouble();
	return scale * Math.pow((percentile / (1 - percentile)), (1/shape));
	
  }
  
  /** */
  public static double halfstudentt(Random random, double nu, double sigma) {
	  double t = studentt(random, nu, 0, 1);
	  return Math.abs(t) * sigma;
  }

  /** */
  public static double laplace(Random random, double location, double scale)
  {
    return new LaplaceDistribution(generator(random), location, scale).sample();
  }
  
  /** */
  public static int geometric(Random random, double prob)
  {
    return new GeometricDistribution(generator(random), prob).sample();
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
  public static double studentt(Random random, double nu, double mu, double sigma)
  {
	  double t = new TDistribution(generator(random), nu).sample();
	  return t * sigma + mu;
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
    if (mean > _poissonSwitchToNormalThreshold) { // this gets slow, mean=524288.0 takes 00:00:00.017; mean = 1.073741824E9 takes00:00:35.639, mean=2.147483648E9 never terminates
      // use normal approximation
      double sample = normal(rand, mean, mean);
      if (sample < 0.0) return 0;
      if (sample > Integer.MAX_VALUE) throw new RuntimeException("Overflow in Poisson generation");
      return (int) sample;
    }
    return new PoissonDistribution(generator(rand), mean, PoissonDistribution.DEFAULT_EPSILON, PoissonDistribution.DEFAULT_MAX_ITERATIONS).sample();
  }
  public static int _poissonSwitchToNormalThreshold = 500_000;
  
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

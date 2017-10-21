package blang.distributions;

import org.apache.commons.math3.distribution.BetaDistribution;
import org.apache.commons.math3.distribution.BinomialDistribution;
import org.apache.commons.math3.distribution.GammaDistribution;
import org.apache.commons.math3.distribution.PoissonDistribution;

import blang.types.DenseSimplex;
import blang.types.StaticUtils;
import xlinear.CholeskyDecomposition;
import xlinear.DenseMatrix;
import xlinear.Matrix;
import xlinear.MatrixOperations;

import static blang.types.ExtensionUtils.generator;

import java.util.Random;

public class Generators 
{
  public static double gamma(Random random, double shape, double rate)
  {
    double result = new GammaDistribution(generator(random), shape, 1.0/rate).sample();
    if (result == 0.0) // avoid crash-inducing zero probability corner cases
      result = ZERO_PLUS_EPS;
    return result;
  }

  public static double beta(Random random, double alpha, double beta)
  {
    double result = new BetaDistribution(generator(random), alpha, beta).sample();
    if (result == 0.0) // avoid crash-inducing zero probability corner cases
      result = ZERO_PLUS_EPS;
    if (result == 1.0)
      result = ONE_MINUS_EPS;
    return result;
  }
  
  public static boolean bernoulli(Random random, double p) 
  {
    if (random instanceof bayonet.distributions.Random)
      return ((bayonet.distributions.Random) random).nextBernoulli(p);
    return bayonet.distributions.Random.nextBernoulli(random, p);
  }
  
  public static int categorical(Random random, double [] probabilities)
  {
    if (random instanceof bayonet.distributions.Random)
      return ((bayonet.distributions.Random) random).nextCategorical(probabilities);
    return bayonet.distributions.Random.nextCategorical(random, probabilities);
  }
  
  public static int binomial(Random random, int numberOfTrials, double probabilityOfSuccess)
  {
    return new BinomialDistribution(generator(random), numberOfTrials, probabilityOfSuccess).sample();
  }
  
  public static double unitRateExponential(Random random)
  {
    return - Math.log(random.nextDouble());
  }
  
  public static double exponential(Random random, double rate)
  {
    return unitRateExponential(random) / rate;
  }
  
  public static double uniform(Random random, double min, double max)
  {
    if (max < min)
      throw new RuntimeException("Invalid arguments " + min + ", " + max);
    return min + random.nextDouble() * (max - min);
  }
  
  public static int discreteUniform(Random rand, int minInclusive, int maxExclusive)
  {
    if (maxExclusive <= minInclusive)
      throw new RuntimeException("Invalid arguments " + minInclusive + ", " + maxExclusive);
    return rand.nextInt(maxExclusive - minInclusive) + minInclusive;
  }
  
  public static DenseSimplex dirichlet(Random random, Matrix concentrations) 
  {
    DenseMatrix result = MatrixOperations.dense(concentrations.nEntries());
    dirichletInPlace(random, concentrations, result);
    return StaticUtils.denseSimplex(result);
  }
  
  static void dirichletInPlace(Random random, Matrix concentrations, Matrix result)
  {
    double sum = 0.0;
    for (int d = 0; d < concentrations.nEntries(); d++)
    {
      double gammaVariate = gamma(random, concentrations.get(d), 1.0);
      result.set(d, gammaVariate);
      sum += gammaVariate;
    }
    result.divInPlace(sum);
  }
  
  public static Matrix multivariateNormal(Random rand, Matrix mean, CholeskyDecomposition precision) 
  {
    return MatrixOperations.sampleNormalByPrecision(rand, precision).add(mean);
  }
  
  public static double normal(Random rand, double mean, double variance)
  {
    return rand.nextGaussian() * Math.sqrt(variance) + mean;
  }
  
  public static int poisson(Random rand, double mean) 
  {
    return new PoissonDistribution(generator(rand), mean, PoissonDistribution.DEFAULT_EPSILON, PoissonDistribution.DEFAULT_MAX_ITERATIONS).sample();
  }
  
  public static final double ZERO_PLUS_EPS = 1e-300;
  public static final double ONE_MINUS_EPS = 1.0 - 1e-16;
  
  private Generators() {}
}

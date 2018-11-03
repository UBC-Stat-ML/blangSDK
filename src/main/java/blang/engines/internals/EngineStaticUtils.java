package blang.engines.internals;

import bayonet.distributions.Multinomial;
import bayonet.smc.ParticlePopulation;
import blang.runtime.SampledModel;

public class EngineStaticUtils
{
  public static double relativeESS(ParticlePopulation<SampledModel> population, double temperature, double nextTemperature, boolean conditional)
  {
    double [] incrementalWeights = incrementalWeights(population, temperature, nextTemperature);
    double 
      numerator   = 0.0,
      denominator = 0.0;
    for (int i = 0; i < population.nParticles(); i++)
    {
      double factor = population.getNormalizedWeight(i) * incrementalWeights[i];
      numerator   += factor;
      denominator += factor * (conditional ? incrementalWeights[i] : factor);
    }
    return numerator * numerator / denominator / (conditional ? 1.0 : population.nParticles()); 
  }
  
  public static double[] incrementalWeights(ParticlePopulation<SampledModel> population, double temperature,
      double nextTemperature)
  {
    double [] result = new double[population.nParticles()];
    for (int i = 0; i < population.nParticles(); i++)
      result[i] = population.particles.get(i).logDensityRatio(temperature, nextTemperature);
    Multinomial.expNormalize(result);
    return result;
  }
  
  /**
   * Computes (1/N^2) \sum_i \sum_j | v_i - v_j | 
   * in O(N) by using the assumption that the v's are sorted in increasing order.
   */
  public static double averageDifference(double [] sortedVs) 
  {
    double sum = 0.0;
    int N = sortedVs.length;
    for (int j = 0; j < N - 1; j++)
    {
      double delta = sortedVs[j+1] - sortedVs[j];
      if (delta < 0.0) throw new RuntimeException("Assuming the Vs are sorted.");
      sum += delta * (j + 1) * (N - j - 1);
    }
    return 2.0 * sum / N / N;
  }
  
}

package blang.engines.internals;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.math3.analysis.solvers.PegasusSolver;

import com.google.common.collect.Ordering;
import com.google.common.primitives.Doubles;

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
   * 
   * @param annealingParameters length N + 1
   * @param acceptanceProbabilities length N, entry i is accept b/w chain i-1 and i
   * @param nGrids number of grids in output partition (including both end points)
   * @return list of size nGrids with optimized partition, sorted in increasing order
   */
  public static List<Double> optimalPartition(List<Double> annealingParameters, List<Double> acceptanceProbabilities, int nGrids) 
  {
    if (annealingParameters.size() != acceptanceProbabilities.size() + 1)
      throw new RuntimeException();
    for (double pr : acceptanceProbabilities)
      if (!(pr >= 0.0 && pr <= 1.0))
         throw new RuntimeException();
    if (!Ordering.natural().isOrdered(annealingParameters))
       throw new RuntimeException();
    
    double [] xs = Doubles.toArray(annealingParameters);
    double [] ys = new double[xs.length];
    for (int i = 1; i < ys.length; i++)
      ys[i] = ys[i-1] + (1.0 - acceptanceProbabilities.get(i-1));
    double Lambda = ys[ys.length - 1];
    
    Spline spline = Spline.createMonotoneCubicSpline(xs, ys);
    
    List<Double> result = new ArrayList<>();
    PegasusSolver solver = new PegasusSolver();
    double previous = 0.0;
    for (int i = 0; i < nGrids; i++) 
    {
      double y = Lambda * i / (nGrids - 1.0);
      double point = solver.solve(10_000, (double x) -> spline.interpolate(x) - y, previous, 1.0);
      result.add(point);
    }
    return result;
  }
  
  public static void main(String [] args) 
  {
    System.out.println(optimalPartition(Arrays.asList(0.0, 0.5, 1.0), Arrays.asList(0.1, 0.9), 5));
  }

}

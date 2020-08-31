package blang.engines.internals;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.analysis.solvers.PegasusSolver;

import com.google.common.collect.Ordering;
import com.google.common.primitives.Doubles;

import bayonet.distributions.Multinomial;
import bayonet.smc.ParticlePopulation;
import blang.engines.internals.Spline.MonotoneCubicSpline;
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
  
  public static List<Double> targetAcceptancePartition(UnivariateFunction cumulativeLambda, double targetAccept) 
  {
    if (!(targetAccept >= 0.0 && targetAccept <= 1.0))
      throw new RuntimeException();
    
    double Lambda = cumulativeLambda.value(1.0);
    int nGrids = Math.max(2, (int) (Lambda / (1.0 - targetAccept)));
    return fixedSizeOptimalPartition(cumulativeLambda, nGrids);
  }
  
  private static double[] cumulativeLambda(List<Double> acceptanceProbabilities) 
  {
    double [] result = new double[acceptanceProbabilities.size() + 1];
    for (int i = 1; i < result.length; i++)
      result[i] = result[i-1] + (1.0 - acceptanceProbabilities.get(i-1));
    return result;
  }

  /**
   * 
   * @param annealingParameters length N + 1
   * @param acceptanceProbabilities length N, entry i is accept b/w chain i-1 and i
   */
  public static MonotoneCubicSpline estimateCumulativeLambda(List<Double> annealingParameters, List<Double> acceptanceProbabilities)
  {
    if (annealingParameters.size() != acceptanceProbabilities.size() + 1)
      throw new RuntimeException();
    for (double pr : acceptanceProbabilities)
      if (!(pr >= 0.0 && pr <= 1.0))
         throw new RuntimeException();
    if (!Ordering.natural().isOrdered(annealingParameters))
      throw new RuntimeException();
        
    double [] xs = Doubles.toArray(annealingParameters);
    double [] ys = cumulativeLambda(acceptanceProbabilities);
    return (MonotoneCubicSpline) Spline.createMonotoneCubicSpline(xs, ys);
  }
  
  /**
   * 
   * @param annealingParameters 
   * @param nGrids number of grids in output partition (including both end points)
   * @return list of size nGrids with optimized partition, sorted in increasing order
   */
  public static List<Double> fixedSizeOptimalPartition(UnivariateFunction cumulativeLambda, int nGrids) 
  {
    double Lambda = cumulativeLambda.value(1.0);
    List<Double> result = new ArrayList<>();
    PegasusSolver solver = new PegasusSolver(1e-10);
    double leftBound = 0.0;
    for (int i = 0; i < nGrids - 1; i++) 
    {
      double y = Lambda * i / (nGrids - 1.0); 
         
      // Ideally, would like to use leftBound, but since that bound is based on an approximate solutions, 
      // we need to relax it to avoid bracketing errors
      double numericallyRobustLeftBound = Math.max(0, leftBound - 0.1); 
      
      double point = solver.solve(10_000, (double x) -> cumulativeLambda.value(x) - y, numericallyRobustLeftBound, 1.0);
      result.add(point);
      leftBound = point;
    }
    result.add(1.0);
    
    Collections.sort(result); // Might need a few minor changes in ordering to get it sorted because of the required bracket relaxation described above
    return result;
  }
}

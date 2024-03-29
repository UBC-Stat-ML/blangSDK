package blang.engines.internals;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.analysis.solvers.PegasusSolver;

import com.google.common.collect.Ordering;
import com.google.common.primitives.Doubles;

import bayonet.distributions.Multinomial;
import bayonet.math.NumericalUtils;
import bayonet.smc.ParticlePopulation;
import blang.engines.internals.Spline.MonotoneCubicSpline;
import blang.runtime.SampledModel;

public class EngineStaticUtils
{
  public static double relativeESS(ParticlePopulation<SampledModel> population, double temperature, double nextTemperature, boolean conditional) {
    if (conditional) 
      return relativeCESS(population, temperature, nextTemperature);
    else
      return _relativeESS(population, temperature, nextTemperature, false);
  }
  
  public static double relativeCESS(ParticlePopulation<SampledModel> population, double temperature, double nextTemperature) {
    double [] logDensityRatios = logDensityRatios(population, temperature, nextTemperature);
    double logNum = 2.0 * previousPopulationLogExpectation(population, logDensityRatios, false);
    double logDenom = previousPopulationLogExpectation(population, logDensityRatios, true);
    return Math.exp(logNum - logDenom);
  }
  
  private static double[] logDensityRatios(ParticlePopulation<SampledModel> population, double temperature, double nextTemperature) {
    double [] result = new double[population.nParticles()];
    for (int i = 0; i < population.nParticles(); i++)
      result[i] = population.particles.get(i).logDensityRatio(temperature, nextTemperature);
    return result;
  }

  private static double previousPopulationLogExpectation(ParticlePopulation<SampledModel> population, double [] logDensityRatios, boolean squared) {
    double result = Double.NEGATIVE_INFINITY;
    for (int i = 0; i < population.nParticles(); i++)
      result = NumericalUtils.logAdd(result, Math.log(population.getNormalizedWeight(i)) + (squared ? 2.0 : 1.0) * logDensityRatios[i]);
    return result;
  }
  
  // TODO: rewrite more numerically stable version
  public static double _relativeESS(ParticlePopulation<SampledModel> population, double temperature, double nextTemperature, boolean conditional)
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
  
  // pad with zero on the left, then cumsum; return as array 
  // to work with the spline function
  private static double[] paddedCumulative(List<Double> x, double nudge) 
  {
    double [] result = new double[x.size() + 1];
    for (int i = 1 /* i = 0 set to zero */; i < result.length; i++)
      result[i] = result[i-1] + x.get(i-1) + nudge;
    return result;
  }
  
  public static List<Double> acceptProbabilitiesToIntensities(List<Double> acceptPrs) 
  {
    List<Double> result = new ArrayList<Double>();
    for (Double acceptPr : acceptPrs) 
    {
      if (!(acceptPr >= 0.0 && acceptPr <= 1.0))
        throw new RuntimeException("Should be a pr: " + acceptPr);
      result.add(1.0 - acceptPr);
    }
    return result;
  }

  /**
   * 
   * @param annealingParameters length N + 1
   * @param acceptanceProbabilities length N, entry i is accept b/w chain i-1 and i
   */
  public static MonotoneCubicSpline estimateCumulativeLambdaFromIntensities(
      List<Double> annealingParameters, 
      List<Double> intensities) {
    return estimateCumulativeFunctionsFromIntensities(annealingParameters, intensities, false, 0.0);
  }
  
  public static MonotoneCubicSpline estimateScheduleGeneratorFromIntensities(
      List<Double> annealingParameters, 
      List<Double> intensities) {
    return estimateCumulativeFunctionsFromIntensities(annealingParameters, intensities, true, 0.0);
  }  
  
  public static MonotoneCubicSpline estimateCumulativeFunctionsFromIntensities(
      List<Double> annealingParameters, 
      List<Double> intensities, 
      boolean returnScheduleGenerator, 
      double nudge)
  {
    if (annealingParameters.size() != intensities.size() + 1)
      throw new RuntimeException();
    for (double intensity : intensities)
      if (!(intensity >= 0.0))
         throw new RuntimeException("Intensities should be non-neg reals: " + intensities);
    if (!Ordering.natural().isOrdered(annealingParameters))
      throw new RuntimeException();
        
    double [] xs = Doubles.toArray(annealingParameters);
    double [] ys = paddedCumulative(intensities, nudge);
    if (returnScheduleGenerator) {
      double norm = ys[ys.length - 1];
      for (int i = 0; i < ys.length; i++) {
        ys[i] /= norm;
        if (i > 0 && ys[i] == ys[i-1]) {
          // The MonotoneCubicSpline code does not handle support point with same 
          // x location. So when we detect a zero normalized intensity grid point, 
          // we instead add a small epsilon to each intensity
          if (nudge > 0) throw new RuntimeException();
          System.out.print("Zero intensities encountered: adding a slight nudge"); 
          return estimateCumulativeFunctionsFromIntensities(annealingParameters, intensities, returnScheduleGenerator, 1e-6);
        }
      }
    }
    return (MonotoneCubicSpline) Spline.createMonotoneCubicSpline(returnScheduleGenerator ? ys : xs, returnScheduleGenerator ? xs : ys);
  }

  public static List<Double> fixedSizeOptimalPartitionFromScheduleGenerator(UnivariateFunction scheduleGenerator, int nGrids) 
  {
    List<Double> result = new ArrayList<>();
    result.add(0.0);
    for (int i = 1; i < nGrids - 1; i++) {
      double u = i / (nGrids - 1.0); 
      double projected = scheduleGenerator.value(u);
      result.add(projected);
    }
    result.add(1.0);
    return result;
  }
  
  /**
   * @deprecated
   * @param annealingParameters 
   * @param nGrids number of grids in output partition (including both end points)
   * @return list of size nGrids with optimized partition, sorted in increasing order
   */
  public static List<Double> fixedSizeOptimalPartition(UnivariateFunction cumulativeLambda, int nGrids) 
  {
    double Lambda = cumulativeLambda.value(1.0);
    List<Double> result = new ArrayList<>();
    PegasusSolver solver = new PegasusSolver(1e-16);
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

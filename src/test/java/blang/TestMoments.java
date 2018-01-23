package blang;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
import org.junit.Assert;
import org.junit.Test;

import bayonet.distributions.Random;
import blang.core.IntVar;
import blang.core.RealVar;
import blang.core.UnivariateModel;
import blang.distributions.Beta;
import blang.distributions.NegativeBinomial;
import blang.mcmc.internals.BuiltSamplers;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

public class TestMoments 
{
  static Random random = new Random(1);
  static Examples examples = new Examples();
  
  @Test
  public void beta() 
  {
    test(10_000_000, (Beta) examples.sparseBeta.model);
  }
  
  @Test
  public void negBin()
  {
    test(10_000_000, (NegativeBinomial) examples.negBinomial.model);
  }
  
  @TestedDistribution(NegativeBinomial.class)
  private static List<Double> negBinMoments(NegativeBinomial negBin) 
  {
    List<Double> result = new ArrayList<>();
    
    result.add(1.0);
    
    double p = negBin.getP().doubleValue(), r = negBin.getR().doubleValue();
    result.add(p * r / (1.0 - p));
    
    return result;
  }
  
  @TestedDistribution(Beta.class)
  private static List<Double> betaRawMoments(Beta distribution) 
  {
    double alpha = distribution.getAlpha().doubleValue();
    double beta = distribution.getBeta().doubleValue();
    double product = 1.0;
    List<Double> result = new ArrayList<>();
    for (int i = 0; i < 4; i++)
    {
      result.add(product);
      product *= (alpha + i) / (alpha + beta + i);
    }
    return result;
  }
  
  @SuppressWarnings({ "unchecked", "rawtypes" })
  public static <T extends UnivariateModel<?>> void test(int nSamples, T distribution)
  {
    System.out.println("Testing moments for " + distribution.getClass().getSimpleName());
    boolean found = false;
    for (Method m : TestMoments.class.getDeclaredMethods())
    {
      TestedDistribution annotation = m.getAnnotation(TestedDistribution.class);
      if (annotation != null && annotation.value() == distribution.getClass())
      {
        if (found)
          throw new RuntimeException("Two methods both providing analytic moments for the same distribution");
        found = true;
        // compute analytical
        List<Double> analyticMoments;
        try 
        {
          analyticMoments = (List) m.invoke(null, distribution);
          List<SummaryStatistics> numeric = empiricalRawMoments(distribution, analyticMoments.size(), random, nSamples);
          for (int d = 0; d < analyticMoments.size(); d++)
          {
            double analytic = analyticMoments.get(d);
            SummaryStatistics currentMCStat = numeric.get(d);
            
            // TODO: instead, control p value computed with multiple testing correction
            double tol = 3.0 * currentMCStat.getStandardDeviation() / Math.sqrt(currentMCStat.getN()); 
            
            System.out.println("d = " + d);
            System.out.println("\tNumeric = " + analytic);
            System.out.println("\tMC = " + currentMCStat.getMean() + " (" + tol + ")");
            Assert.assertEquals(analytic, currentMCStat.getMean(), tol);
          }
        } 
        catch (Exception e) { throw new RuntimeException(e); }
      }
    }
    if (!found)
      throw new RuntimeException("Did not find method providing analytic moments");
  }
  
  private static <T extends UnivariateModel<?>> List<SummaryStatistics> empiricalRawMoments(T distribution, int maxDegree, Random random, int nSamples)
  {
    List<SummaryStatistics> result = new ArrayList<SummaryStatistics>();
    for (int d = 0; d <= maxDegree; d++)
      result.add(new SummaryStatistics());
    SampledModel sampledModel = new SampledModel(new GraphAnalysis(distribution), new BuiltSamplers());
    for (int i = 0; i < nSamples; i++)
    {
      sampledModel.forwardSample(random, true); 
      //distribution.generate(random);
      Object realization = distribution.realization();
      double current; 
      if (realization instanceof RealVar)
        current = ((RealVar) realization).doubleValue();
      else if (realization instanceof IntVar)
        current = ((IntVar) realization).intValue();
      else
        throw new RuntimeException();
      for (int d = 0; d < maxDegree; d++)
        result.get(d).addValue(Math.pow(current, d));
    }
    return result;
  }
   
  @Retention(RetentionPolicy.RUNTIME)
  public static @interface TestedDistribution
  {
    Class<? extends UnivariateModel<?>> value();
  }

}

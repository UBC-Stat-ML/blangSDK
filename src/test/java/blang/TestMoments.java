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
import blang.core.ForwardSimulator;
import blang.core.RealVar;
import blang.core.UnivariateModel;
import blang.distributions.Beta;

public class TestMoments 
{
  static Random random = new Random(1);
  static Examples examples = new Examples();
  
  @Test
  public void beta() 
  {
    test(10_000_000, (Beta) examples.sparseBeta.model);
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
  public static <T extends UnivariateModel<RealVar> & ForwardSimulator> void test(int nSamples, T distribution)
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
            double tol = currentMCStat.getStandardDeviation() / Math.sqrt(currentMCStat.getN()); 
            
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
  
  private static <T extends UnivariateModel<RealVar> & ForwardSimulator> List<SummaryStatistics> empiricalRawMoments(T distribution, int maxDegree, Random random, int nSamples)
  {
    List<SummaryStatistics> result = new ArrayList<SummaryStatistics>();
    for (int d = 0; d <= maxDegree; d++)
      result.add(new SummaryStatistics());
    for (int i = 0; i < nSamples; i++)
    {
      distribution.generate(random);
      double current = distribution.realization().doubleValue();
      for (int d = 0; d < maxDegree; d++)
        result.get(d).addValue(Math.pow(current, d));
    }
    return result;
  }
   
  @Retention(RetentionPolicy.RUNTIME)
  public static @interface TestedDistribution
  {
    Class<? extends UnivariateModel<RealVar>> value();
  }

}

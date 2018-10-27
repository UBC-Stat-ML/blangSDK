package blang;

import org.junit.Test;

import blang.core.IntDistribution;
import blang.distributions.Generators;
import blang.distributions.YuleSimon;
import blang.types.StaticUtils;
import blang.validation.NormalizationTest;

public class TestSDKNormalizations extends NormalizationTest
{
  private Examples examples = new Examples();
  
  @Test
  public void normal()
  {
    // check norm from -infty to +infty (by doubling domain of integration)
    checkNormalization(examples.normal.model); 
  }
  
  @Test
  public void beta()
  {
    // check norm on a close interval
    checkNormalization(examples.beta.model, Generators.ZERO_PLUS_EPS, Generators.ONE_MINUS_EPS);
  }
  
  @Test
  public void testExponential()
  {
    // approximate 0, infty interval
    checkNormalization(examples.exp.model, 0.0, 10.0);
  }
  
  @Test
  public void testGamma()
  {
    checkNormalization(examples.gamma.model, 0.0, 15.0); 
  }
  
  @Test
  public void testYuleSimon()
  {
    IntDistribution distribution = YuleSimon.distribution(StaticUtils.fixedReal(3.5));
    double sum = 0.0;
    for (int i = 0; i < 100; i++)
      sum += Math.exp(distribution.logDensity(i));
    System.out.println(sum);
  }
  
}

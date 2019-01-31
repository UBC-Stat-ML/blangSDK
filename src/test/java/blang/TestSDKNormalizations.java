package blang;

import org.junit.Assert;
import org.junit.Test;

import blang.core.IntDistribution;
import blang.distributions.Generators;
import blang.distributions.YuleSimon;
import blang.types.StaticUtils;
import blang.validation.NormalizationTest;
import humi.BetaNegativeBinomial;

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
    Assert.assertEquals(1.0, sum, 0.01);
  }
  
  @Test
  public void testBNB()
  {
    IntDistribution distribution = BetaNegativeBinomial.distribution(StaticUtils.fixedReal(3.5), StaticUtils.fixedReal(1.2), StaticUtils.fixedReal(3.0));
    double sum = 0.0;
    for (int i = 0; i < 1000; i++)
      sum += Math.exp(distribution.logDensity(i));
    Assert.assertEquals(1.0, sum, 0.01);
  }
  
}

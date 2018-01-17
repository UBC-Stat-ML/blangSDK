package blang;

import org.junit.Test;

import blang.distributions.Generators;
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
}

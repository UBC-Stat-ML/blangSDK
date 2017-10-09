package blang.validation.internals.tests;

import org.junit.Test;

import blang.distributions.Normal;
import blang.distributions.Normal.Builder;
import blang.types.StaticUtils;
import blang.validation.ExactTest;

public class TestExactSDKDistributions 
{
  @Test
  public void test()
  {
    ExactTest exact = new ExactTest();
    
    exact.addTest( 
        new Normal.Builder().setMean(() -> 0.2).setVariance(() -> 0.1).setRealization(StaticUtils.realVar(1.0)).build(), 
        normal -> Math.pow(normal.realization().doubleValue(), 2.0)
    );
    
    System.out.println(exact.pValues());
  }
}

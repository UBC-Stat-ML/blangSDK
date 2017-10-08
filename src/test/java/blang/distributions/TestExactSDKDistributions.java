package blang.distributions;

import org.junit.Test;

import blang.runtime.ExactTest;
import blang.types.StaticUtils;

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

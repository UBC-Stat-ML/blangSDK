package blang.distributions;

import org.junit.Test;

import blang.runtime.ExactTest;
import blang.runtime.TestSupport;
import blang.types.StaticUtils;

/**
 * A test for the exact test, to make sure 
 */
public class TestExactTest 
{
  @Test
  public void checkBadNormalDetected()
  {
    TestSupport.setOkToUseDefectiveImplementation();
    
    ExactTest exact = new ExactTest();
    
    exact.addTest(
        new BadNormal.Builder().setMean(() -> 0.2).setVariance(() -> 0.1).setRealization(StaticUtils.realVar(1.0)).build(), 
        normal -> Math.pow(normal.realization().doubleValue(), 2.0)
    );
    
    System.out.println(exact.pValues());
  }
}

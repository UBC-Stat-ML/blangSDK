package blang.validation.internals.tests;

import org.junit.Test;

import blang.types.StaticUtils;
import blang.validation.ExactTest;
import blang.validation.internals.Helpers;
import blang.validation.internals.fixtures.BadNormal;

/**
 * A test for the exact test, to make sure 
 */
public class TestExactTest 
{
  @Test
  public void checkBadNormalDetected()
  {
    Helpers.setOkToUseDefectiveImplementation();
    
    ExactTest exact = new ExactTest();
    
    exact.addTest(
        new BadNormal.Builder().setMean(() -> 0.2).setVariance(() -> 0.1).setRealization(StaticUtils.realVar(1.0)).build(), 
        normal -> Math.pow(normal.realization().doubleValue(), 2.0)
    );
    
    System.out.println(exact.pValues());
  }
}

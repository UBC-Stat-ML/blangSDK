package blang.runtime;

import org.junit.Assert;
import org.junit.Test;

import blang.validation.internals.Helpers;
import blang.validation.internals.fixtures.PCR;

public class TestSampledModel 
{
  
  @Test
  public void test() 
  {
    Helpers.setDefectiveImplementationStatus(true);
    Runner runner = new Runner(new PCR.Builder());
    try 
    {
      runner.run();
    } 
    catch (RuntimeException re) 
    {
      Assert.assertEquals(re.getMessage(), SampledModel.INVALID_LOG_RATIO);
      return;
    }
    Assert.fail();
  }

}

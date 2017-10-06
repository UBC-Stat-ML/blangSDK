package blang.runtime;

import org.junit.Test;

import blang.core.ModelBuilder;
import blang.testmodel.Cyclic;
import blang.testmodel.Cyclic.Builder;
import blang.testmodels.GenerateTwice;
import blang.testmodels.NotAllRandomHaveDistributions;

public class TestRunner 
{

  
  @Test
  public void checkCyclesDetected()
  {
    checkDAGViolation(new Cyclic.Builder());
  }
  
  @Test
  public void checkGeneratedTwiceDetected()
  {
    checkDAGViolation(new GenerateTwice.Builder());
  }
  
  @Test
  public void checkNotAllRandHaveDistDetected()
  {
    checkDAGViolation(new NotAllRandomHaveDistributions.Builder());
  }
  
  public void checkDAGViolation(ModelBuilder builder)
  {
    Runner runner = new Runner(builder);
    TestSupport.assertTypeOfThrownExceptionMatches(() -> runner.run(), new Runner.NotDAG(""));
  }
}

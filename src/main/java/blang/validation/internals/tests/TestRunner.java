package blang.validation.internals.tests;

import org.junit.Test;

import blang.core.ModelBuilder;
import blang.runtime.Runner;
import blang.runtime.Runner.NotDAG;
import blang.testmodel.Cyclic;
import blang.testmodels.GenerateTwice;
import blang.testmodels.NotAllRandomHaveDistributions;
import blang.validation.internals.Helpers;

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
    Helpers.assertTypeOfThrownExceptionMatches(() -> runner.run(), new Runner.NotDAG(""));
  }
}

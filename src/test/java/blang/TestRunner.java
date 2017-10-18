package blang;

import org.junit.Test;

import blang.core.ModelBuilder;
import blang.runtime.Runner;
import blang.testmodel.Cyclic;
import blang.testmodels.GenerateTwice;
import blang.validation.internals.Helpers;
import blang.validation.internals.fixtures.Simple;

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
  public void checkSimpleOK()
  {
    new Runner(new Simple.Builder()).run();
  }
  
  public void checkDAGViolation(ModelBuilder builder)
  {
    Runner runner = new Runner(builder);
    Helpers.assertTypeOfThrownExceptionMatches(() -> runner.run(), new Runner.NotDAG(""));
  }
}

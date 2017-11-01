package blang.tests;

import org.junit.Assert;
import org.junit.Test;

import blang.core.ModelBuilder;
import blang.inits.experiments.Experiment;
import blang.runtime.Runner;
import blang.tests.fixtures.Cyclic;
import blang.tests.fixtures.GenerateTwice;
import blang.tests.fixtures.Helpers;
import blang.tests.fixtures.Simple;
import blang.tests.fixtures.UnspecifiedParam;

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
  
  @Test
  public void testMissingParam()
  {
    // A RealVar as parameter without default ?: provided should prompt a CLI parsing error
    // Keep this check to ensure parsing behaviour of RealVar, etc does not get too liberal
    Assert.assertEquals(Runner.start(UnspecifiedParam.class.getCanonicalName()), Experiment.CLI_PARSING_ERROR_CODE);
  }
  
  public void checkDAGViolation(ModelBuilder builder)
  {
    Runner runner = new Runner(builder);
    Helpers.assertTypeOfThrownExceptionMatches(() -> runner.run(), new Runner.NotDAG(""));
  }
}

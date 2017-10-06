package blang.runtime;

import java.util.Collections;

import org.junit.Test;

import blang.runtime.internals.UncoveredVariables;
import blang.testmodels.MissingSampler;
import blang.testmodels.UnsamplableType;

public class TestRunner 
{
  @Test
  public void testUncoveredVariablesDetected() {
    Runner runner = new Runner(new MissingSampler.Builder());
    TestSupport.assertThrownExceptionMatches(() -> runner.run(), new UncoveredVariables(Collections.singleton(UnsamplableType.class)));
  }
}

package blang

import blang.validation.ExactInvarianceTest
import org.junit.Test
import blang.validation.DeterminismTest
import blang.distributions.Generators

class TestSDKDistributions { 
  
  @Test 
  def void exactInvarianceTest() {
    val oldThreshold = Generators._poissonSwitchToNormalThreshold
    Generators._poissonSwitchToNormalThreshold = Examples.largeLambda - 10
    test(new ExactInvarianceTest)
    Generators._poissonSwitchToNormalThreshold = oldThreshold
  }

  def static void test(ExactInvarianceTest test) {
    setup(test)
    println("Corrected pValue = " + test.correctedPValue)
    test.check()
  }
  
  def static void setup(ExactInvarianceTest test) {
    test => [ 
      nPosteriorSamplesPerIndep = 500 // 1000 creates a travis time out
      for (instance : new Examples().all) {
        test.add(instance)
      }
    ]
  }
  
  @Test
  def void determinismTest() {
    new DeterminismTest => [
      for (instance : new Examples().all) {
        check(instance)
      }
    ]
  } 
}

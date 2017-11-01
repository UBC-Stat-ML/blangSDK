package blang.tests

import blang.validation.ExactInvarianceTest
import org.junit.Test
import blang.validation.DeterminismTest

class TestSDKDistributions { 
  
  @Test
  def void determinismTest() {
    new DeterminismTest => [
      for (instance : new Examples().all) {
        check(instance)
      }
    ]
  } 
  
  @Test 
  def void exactInvarianceTest() {
    test(new ExactInvarianceTest)
  }

  def static void test(ExactInvarianceTest test) {
    setup(test)
    println("Corrected pValue = " + test.correctedPValue)
    test.check()
  }
  
  def static void setup(ExactInvarianceTest test) {
    test => [ 
      nPosteriorSamplesPerIndep = 10
      for (instance : new Examples().all) {
        test.add(instance)
      }
    ]
  }
}

package blang

import blang.validation.ExactInvarianceTest
import org.junit.Test
import blang.validation.DeterminismTest

class TestSDKDistributions { 
  
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

package blang.tests

import org.junit.Test
import blang.validation.ExactInvarianceTest

class TestDeep {
  
  // One model, many iterations
  @Test
  def void test() {
    val test = new ExactInvarianceTest => [ 
      nPosteriorSamplesPerIndep = 1_000
      add(new Examples().shm)
    ]
    test.check
  }
}
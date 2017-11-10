package blang

import blang.validation.ExactInvarianceTest
import blang.validation.ExactInvarianceTest.TTest
import org.junit.Test
import bayonet.distributions.Random
import bayonet.math.NumericalUtils
import org.apache.commons.math3.special.Gamma

class TestDeep {
  
  
//   next steps:
//   
//   - try many models with deep KS to see if it affects other models
//   - try simpler MH samplers, integers, etc
//   ** careful about duplicates
  
//  @Test
  def void testSimpleDiri()
  {
    val exactTest = new ExactInvarianceTest => [ 
      random = new Random(14)
//      test = new TTest // KS unreliable at that regime (known issue)
      nPosteriorSamplesPerIndep = 500
      add(new Examples().dirichlet3)
    ]
    exactTest.check 
    
    // OK problem fixed! 
    // crashes as expected for non-symmetric Simplex sampler, but not for the symmetrized version
  }
  
  
  
//  @Test
  def void testDiri()
  {
    val exactTest = new ExactInvarianceTest => [ 
      random = new Random(14)
//      test = new TTest // KS unreliable at that regime (known issue)
      nPosteriorSamplesPerIndep = 500
      add(new Examples().deep_diri)
    ]
    exactTest.check 
    
    // OK problem fixed! 
    // crashes as expected for non-symmetric Simplex sampler, but not for the symmetrized version
  }
  
//    @Test
  def void testBetaComplex()
  {
    val exactTest = new ExactInvarianceTest => [ 
      random = new Random(14)
//      test = new TTest // KS unreliable at that regime (known issue)
      nPosteriorSamplesPerIndep = 500
      add(new Examples().deep_beta)
    ]
    exactTest.check 
    
    // OK problem fixed! 
    // crashes as expected for non-symmetric Simplex sampler, but not for the symmetrized version
  }
  
  @Test   // - See #62
  def void testBeta()
  {
    val exactTest = new ExactInvarianceTest => [ 
//      test = new TTest // KS unreliable at that regime (known issue)
      nPosteriorSamplesPerIndep = 500
      add(new Examples().sparseBeta2)
    ]
    exactTest.check 
    //java.lang.AssertionError: Some test(s) failed: Deep_Beta RealSliceSampler  Examples$$Lambda$59/1667148529  8.115646289269902E-4  0.49728108308389274(0.0023010819891994454)  0.48652042734957585(0.0022420874721325425)
  }
}
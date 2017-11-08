package blang

import org.junit.Test
import blang.validation.ExactInvarianceTest
import blang.validation.Instance
import blang.mcmc.internals.SamplerBuilderOptions
//import blang.validation.internals.fixtures.FixedIntervalRealSliceSampler
import blang.mcmc.Sampler
import blang.mcmc.RealSliceSampler
import blang.validation.internals.fixtures.RealNaiveMHSampler
import blang.validation.ExactInvarianceTest.TTest

class TestDeep {
  
//  @Test
  def void testBeta()
  {
    val exactTest = new ExactInvarianceTest => [ 
      test = new TTest // KS unreliable at that regime (known issue)
      nPosteriorSamplesPerIndep = 500
      add(new Examples().deep_beta)
    ]
    exactTest.check 
    
    //java.lang.AssertionError: Some test(s) failed: Deep_Beta RealSliceSampler  Examples$$Lambda$59/1667148529  8.115646289269902E-4  0.49728108308389274(0.0023010819891994454)  0.48652042734957585(0.0022420874721325425)
  }
  
  @Test
  def void testDiri()
  {
    val exactTest = new ExactInvarianceTest => [ 
      test = new TTest // KS unreliable at that regime (known issue)
      nPosteriorSamplesPerIndep = 2000
      add(new Examples().deep_diri)
    ]
    exactTest.check 
    
    // OK problem fixed! 
    // crashes as expected for non-symmetric Simplex sampler, but not for the symmetrized version
    
  }
  
//  
//  /*
//   * Current hypothesis of what goes wrong:
//   * 
//   * - problem was isolated to be with Beta, not Plate machinery
//   * - problem with posterior, not prior (by symmetry should indeed by 0.5)
//   * - might be numerical asymmetry of values close to 0.0 vs. close to 1.0
//   * - one solution would be to use Dirichlet only (and symmetrize it)
//   * 
//   */
//  
//  def getInstance(Class<? extends Sampler> samplerType) {
//    val baseInstance = new Examples().shm2;
//    return new Instance(
//      baseInstance.model, 
//      SamplerBuilderOptions.startWithOnly(samplerType),
//      [p0.doubleValue ** 2])
//  }
//  
//  // One model, many iterations
//  @Test
//  def void testFull() {
//    
//    val exactTest = new ExactInvarianceTest => [ 
//      test = new TTest // KS unreliable at that regime (known issue)
//      nPosteriorSamplesPerIndep = 500
//      add(new Examples().shm2)
//    ]
//    exactTest.check 
//    
//    //java.lang.AssertionError: Some test(s) failed:
//// SimpleHierarchicalModel RealSliceSampler  Examples$$Lambda$58/769429195 0.004945125996996924  0.4990860115990737(0.0028636331978742647) 0.48914247859778714(0.0027814289934902595)
//  
//  }
//  
////  @Test
//  def void testFixedSlice() {
//    testFixedSlice(true)
//    
//    // 10k; 1k makes it fail too
//    // java.lang.AssertionError: Some test(s) failed:
////    SimpleHierarchicalModel FixedIntervalRealSliceSampler Examples$$Lambda$58/769429195 3.787695317614137E-6  0.4990860115990737(0.0028636331978742647) 0.48348754897233664(0.0027670830384704083)
//  
//  }
//  
////  @Test
//  def void testFixedSliceWithReject() {
//    testFixedSlice(false)   // seems to take a while!
//  }
//  
//  def void testFixedSlice(boolean useShrink) {
//    FixedIntervalRealSliceSampler.useShrink = useShrink
//    val test = new ExactInvarianceTest => [ 
//      nPosteriorSamplesPerIndep = 1000 
//      add(getInstance(FixedIntervalRealSliceSampler))
//    ]
//    test.check
//  }
//  
////  @Test
//  def void testNaive() { 
//    
//    val test = new ExactInvarianceTest => [ 
//      nPosteriorSamplesPerIndep = 500_000
//      add(getInstance(RealNaiveMHSampler))
//    ]
//    test.check
//    
//    // Ah! ah! starting to look like the problem is with the 
//    // plate machinery, not with slice samplers!
//    // Perhaps dependencies not correctly inferred?
//    
//    // 10k was close to be able to reject but not quite (1/2 percent I believe?)
//    
//    // No! Actually more iteration made it work...
//    
//    // 50_000
////    Running ExactInvarianceTest on model SimpleHierarchicalModel [RealNaiveMHSampler]
////    All tests passed:
////    SimpleHierarchicalModel RealNaiveMHSampler  Examples$$Lambda$58/769429195 0.20432913825269106 0.4990860115990737(0.0028636331978742647) 0.4983735438942771(0.0028285542189818657)
//    
//    // 500 k
//    // SimpleHierarchicalModel  RealNaiveMHSampler  Examples$$Lambda$58/769429195 0.04639955980304189 0.4990860115990737(0.0028636331978742647) 0.4872748183229586(0.0028420910279294627)
//    
//    
//  }
}
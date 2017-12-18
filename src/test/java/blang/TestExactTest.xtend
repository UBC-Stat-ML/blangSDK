package blang

import blang.mcmc.internals.SamplerBuilderOptions
import blang.types.StaticUtils
import blang.validation.ExactInvarianceTest
import blang.validation.internals.Helpers
import blang.validation.internals.fixtures.BadNormal
import blang.validation.internals.fixtures.BadRealSliceSampler
import blang.validation.internals.fixtures.Multimodal
import blang.validation.internals.fixtures.RealRealizationSquared
import org.junit.After
import org.junit.Assert
import org.junit.Before
import org.junit.Test
import blang.validation.Instance import blang.types.RealScalar

/** 
 * A test for the exact test, to make sure it catches some common types of errors.
 */
class TestExactTest {
  
  @SuppressWarnings("unchecked") @Test def void checkBadNormalDetected() {
    var ExactInvarianceTest test = new ExactInvarianceTest()
    test.add(new Instance(
      new BadNormal.Builder().setMean(StaticUtils.constant(0.2)).setVariance(StaticUtils.constant(0.1)).setRealization(new RealScalar(1.0)).build(),
      new RealRealizationSquared()))
    ensureTestFails(test)
  }
  
  @Test
  def void checkBadSliceSamplerDetected() {
    var ExactInvarianceTest test = new ExactInvarianceTest()
    var SamplerBuilderOptions samplers = SamplerBuilderOptions.startWithOnly(BadRealSliceSampler)
      
    test.add(new Instance(
      new Multimodal.Builder().build,
      samplers,
      new RealRealizationSquared()
    ))
    ensureTestFails(test)
  }
  
  def void ensureTestFails(ExactInvarianceTest test) {
    val double referenceFamilyWiseErrorThreshold = getMainTestPValue()
    Assert.assertTrue(test.nTests() > 0)
    println("Threshold derived from TestSDKDistributions:" + referenceFamilyWiseErrorThreshold)
    println("Expecting " + test.nTests() + " failed test: \n" + ExactInvarianceTest::format(test.results))
    Assert.assertEquals(test.failedTests(referenceFamilyWiseErrorThreshold).size(), test.nTests())
    println
  }

  @Before
  def void before() {
    Helpers.setDefectiveImplementationStatus(true)
  }
  
  @After
  def void after() {
    Helpers.setDefectiveImplementationStatus(false)
  }

  def private double getMainTestPValue() {
    var ExactInvarianceTest lazyTest = new ExactInvarianceTest(true)
    TestSDKDistributions.setup(lazyTest)
    return lazyTest.correctedPValue
  }
}

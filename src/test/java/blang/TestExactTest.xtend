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

/** 
 * A test for the exact test, to make sure it catches some common types of errors.
 */
class TestExactTest {
  
  @SuppressWarnings("unchecked") @Test def void checkBadNormalDetected() {
    var ExactInvarianceTest test = new ExactInvarianceTest()
    test.add(
      new BadNormal.Builder().setMean([0.2]).setVariance([0.1]).setRealization(StaticUtils.realVar(1.0)).build(),
      new RealRealizationSquared())
    ensureTestFails(test)
  }
  
  @Test
  def void checkBadSliceSamplerDetected() {
    var ExactInvarianceTest test = new ExactInvarianceTest()
    var SamplerBuilderOptions samplers = new SamplerBuilderOptions => [
      useAnnotation = false
      additional.add(BadRealSliceSampler)
    ]
      
    test.add(
      new Multimodal.Builder().build,
      samplers,
      new RealRealizationSquared()
    )
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

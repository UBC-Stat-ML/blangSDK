package blang.runtime

import org.junit.Assert

class TestSupport {
  def static void assertThrownExceptionMatches(Runnable code, Throwable expectedException) {
    assertThrownExceptionMatches(code, expectedException, true)
  }
  
  def static void assertTypeOfThrownExceptionMatches(Runnable code, Throwable expectedException) {
    assertThrownExceptionMatches(code, expectedException, false)
  }
  
  def private static void assertThrownExceptionMatches(Runnable code, Throwable expectedException, boolean checkMessage) {
    var Throwable thrown = null
    try { 
      code.run
    }
    catch (Throwable t) { 
      thrown = t
    }
    val String expectedStr = "" + if (checkMessage) expectedException?.toString else expectedException?.class.simpleName
    val String actualStr   = "" + if (checkMessage) thrown?.toString else thrown?.class?.simpleName
    val boolean ok = expectedStr == actualStr
    Assert.assertTrue("Expected exception: " + expectedStr + "; got: " + actualStr , ok)
  }
  
  /*
   * It is sometimes useful to create test fixtures that are intentionally incorrect, 
   * to test the sensitivity of unit tests.
   * The static constructs below ensure that the intentionally incorrect fixtures are not used accidentally.
   */
  
  private static boolean okToUseDefectiveImplementation = false
  
  /**
   * Call this first when testing intentionally incorrect fixtures.
   */
  def static void setOkToUseDefectiveImplementation() {
    okToUseDefectiveImplementation = true
  }
 
  /**
   * Add a call to this in the constructor/method of interest of intentionally incorrect fixtures
   */
  def static void checkOkToUseDefectiveImplementation() {
    if (!okToUseDefectiveImplementation) {
      throw new RuntimeException("An intentionally defective implementation is being accidentally used. Check the stack trace, there is a class in there that should only be used for testing sensitivity of unit tests.")
    }
  }
}
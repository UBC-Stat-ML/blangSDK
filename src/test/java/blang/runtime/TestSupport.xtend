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
}
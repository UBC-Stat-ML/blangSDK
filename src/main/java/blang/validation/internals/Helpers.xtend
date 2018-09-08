package blang.validation.internals

import org.junit.Assert
import blang.validation.internals.fixtures.RealRealizationSquared
import blang.validation.internals.fixtures.IntRealizationSquared
import blang.validation.internals.fixtures.VectorHash
import blang.validation.internals.fixtures.ListHash
import blang.validation.internals.fixtures.IntListFirstComponentOfRealizationSquared
import java.io.File
import briefj.BriefIO

class Helpers {
  
  public val static RealRealizationSquared realRealizationSquared = new RealRealizationSquared()
  public val static IntRealizationSquared intRealizationSquared = new IntRealizationSquared()
  public val static IntListFirstComponentOfRealizationSquared IntListFirstComponentRealizationSquared = new IntListFirstComponentOfRealizationSquared()
  public val static VectorHash vectorHash = new VectorHash()
  public val static ListHash listHash = new ListHash()
  
  
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
  def static void setDefectiveImplementationStatus(boolean useBadIsOk) {
    okToUseDefectiveImplementation = useBadIsOk
  }
 
  /**
   * Add a call to this in the constructor/method of interest of intentionally incorrect fixtures
   */
  def static void checkOkToUseDefectiveImplementation() {
    if (!okToUseDefectiveImplementation) {
      throw new RuntimeException("An intentionally defective implementation is being accidentally used. Check the stack trace, there is a class in there that should only be used for testing sensitivity of unit tests.")
    }
  }
  
  def static void generateQQPlotScript(String fFile, String fpFile, String plotName, File destination) {
    val String output = '''
      #!/usr/bin/env Rscript
      require("ggplot2")
      require("readr")
      f  <- sort((read_csv("«fFile »", col_names = FALSE))$X1)
      fp <- sort((read_csv("«fpFile»", col_names = FALSE))$X1)
      plot <- ggplot() + geom_point(aes(x = f, y = fp), size = 0.001) + geom_abline(intercept = 0, slope = 1)
      ggsave("«plotName»", plot)
    '''
    BriefIO.write(destination, output)
  }
}
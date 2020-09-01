package blang

import org.junit.Test
import blang.runtime.internals.doc.contents.BuiltInDistributions
import blang.xdoc.DocElementExtensions

class TestDocumentation {
  @Test
  def void checkComplete() {
    DocElementExtensions::checkCommentsComplete = true
    new BuiltInDistributions
    DocElementExtensions::checkCommentsComplete = false
  }
}
package blang.runtime

import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.objectgraph.Inputs
import org.eclipse.xtend.lib.annotations.Accessors

@Data
class InitContext {
  
  val public static KEY = "INIT_CONTEXT_KEY"
  
  @Accessors(PUBLIC_GETTER)
  val Inputs graphAnalysisInputs = new Inputs
  
  def void markAsObserved(Object object, boolean recursively) {
    graphAnalysisInputs.markAsObserved(object, recursively)
  }
}
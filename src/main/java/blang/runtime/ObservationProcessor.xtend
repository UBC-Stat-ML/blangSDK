package blang.runtime

import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.objectgraph.Inputs
import org.eclipse.xtend.lib.annotations.Accessors

@Data
class ObservationProcessor {
  
  @Accessors(PUBLIC_GETTER)
  val Inputs graphAnalysisInputs = new Inputs
  
  def <T> T markAsObserved(T object) {
    graphAnalysisInputs.markAsObserved(object, true)
    return object
  }
}
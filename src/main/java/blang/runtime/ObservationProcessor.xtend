package blang.runtime

import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.objectgraph.Inputs
import org.eclipse.xtend.lib.annotations.Accessors

@Data
class ObservationProcessor {
  
  val public static KEY = "OBSERVATION_PROCESSOR"
  
  @Accessors(PUBLIC_GETTER)
  val Inputs graphAnalysisInputs = new Inputs
  
  // make it nicer: recursively by default?
  def <T> T markAsObserved(T object) {
    graphAnalysisInputs.markAsObserved(object, true)
    return object
  }
}
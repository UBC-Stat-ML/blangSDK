package blang.runtime

import org.eclipse.xtend.lib.annotations.Data
import java.util.LinkedHashSet
import blang.runtime.objectgraph.AccessibilityGraph.Node
import blang.runtime.objectgraph.ObjectNode

@Data
class Observations {
  /**
   * All nodes accessible from these roots will be marked as observed in the accessibility graph analysis.
   */
  val LinkedHashSet<Node> observationRoots = new LinkedHashSet<Node>()
  def <T> T markAsObserved(T object) {
    observationRoots.add(new ObjectNode(object))
    return object
  }
}
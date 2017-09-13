package blang.runtime

import org.eclipse.xtend.lib.annotations.Data
import java.util.LinkedHashSet
import blang.runtime.objectgraph.ObjectNode
import blang.runtime.objectgraph.AccessibilityGraph.Node

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
  
  def void markAsObserved(Node node) {
    observationRoots.add(node)
  }
  
  // Catch some possible mistakes:
  
  def void markAsObserved(double object) {
    throw new RuntimeException
  }
  
  def void markAsObserved(int object) {
    throw new RuntimeException
  }
}
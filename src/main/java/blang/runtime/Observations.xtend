package blang.runtime

import org.eclipse.xtend.lib.annotations.Data
import java.util.LinkedHashSet
import blang.runtime.internals.objectgraph.StaticUtils
import blang.runtime.internals.objectgraph.Node

@Data
class Observations {
  /**
   * All nodes accessible from these roots will be marked as observed in the accessibility graph analysis.
   */
  val LinkedHashSet<Node> observationRoots = new LinkedHashSet<Node>()
  
  def <T> T markAsObserved(T object) {
    val Node node = StaticUtils::node(object)
    observationRoots.add(node)
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
package blang.runtime.internals.objectgraph;

import java.io.File;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

import org.apache.commons.lang3.tuple.Pair;
import org.jgrapht.DirectedGraph;
import org.jgrapht.traverse.BreadthFirstIterator;

import bayonet.graphs.DotExporter;
import bayonet.graphs.GraphUtils;



/**
 * An accessibility graph provides the low level data structure used to construct factor graph automatically. 
 * 
 * An accessibility graph is 
 * a directed graph that keeps track of (a superset of) accessibility relationships between java objects. This is used to answer 
 * questions such as: does factor f1 and f2 both have access to an object with a mutable fields which 
 * is unobserved? 
 * 
 * Note: 
 *  - accessibility via global (static) fields is assumed not to be used throughout this inference.
 *  - visibility (public/private/protected) is ignored when establishing accessibility. To understand why, 
 *    say object o1 has access to o2, which has a private field to o3. Even though o1 may not have direct access to o3,
 *    o2 may have a public method giving effective access to it. Hence, we do want to have a path from o1 to o3 (via 
 *    edges (o1, o2), (o2, o3) indicating that there may be accessibility from o1 to o3.
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 *
 */
public class AccessibilityGraph
{
  /**
   * There is no edge in the graph between node n1 and n2 if a method having access to only n1 cannot have
   * access to n2 (unless it uses static fields).
   * 
   * Note that the semantics of this relation is described using the negative voice since we can only hope to 
   * get a super-set of accessibility relationships. This is similar to graphical models, where only the 
   * absence of edge is informative strictly speaking.. 
   */
  public final DirectedGraph<Node, Pair<Node, Node>> graph = GraphUtils.newDirectedGraph();
  
  /**
   * The root of the graph, i.e. where the accessibility analysis was initiated
   */
  public final LinkedHashSet<ObjectNode<?>> roots = new LinkedHashSet<>();
  
  /**
   * Note that in the graph, object nodes points to constituent nodes only; and constituent nodes points to object nodes only. 
   * Constituent nodes always have at most one outgoing edge (zero in the case of primitives), and object nodes can have zero, one, or 
   * more constituents. 
   */
  private <K> void addEdgeAndVertices(ObjectNode<?> objectNode, ConstituentNode<K> constituentNode)
  {
    _addEdgeAndVertices(objectNode, constituentNode);
  }
  
  /**
   * See addEdgeAndVertices(ObjectNode objectNode, ConstituentNode<K> constituentNode)
   */
  private <K> void addEdgeAndVertices(ConstituentNode<K> constituentNode, ObjectNode<?> objectNode)
  {
    _addEdgeAndVertices(constituentNode, objectNode);
  }
  
  private void _addEdgeAndVertices(Node source, Node destination)
  {
    graph.addVertex(source);
    graph.addVertex(destination);
    graph.addEdge(source, destination);
  }
  
  /**
   */
  public AccessibilityGraph()
  {
    this(ExplorationRules.defaultExplorationRules);
  }
  
  public AccessibilityGraph(List<ExplorationRule> explorationRules)
  {
    this.explorationRules = explorationRules;
  }
  
  private final List<ExplorationRule> explorationRules;
  
  public void add(Object root)
  {
    add(new ObjectNode<>(root));
  }
  
  public void add(ObjectNode<?> root)
  {
    roots.add(root);
    
    if (graph.vertexSet().contains(root))
      return; // in case a root is a subset of another
    
    final LinkedList<ObjectNode<?>> toExploreQueue = new LinkedList<>();
    toExploreQueue.add(root);
    
    while (!toExploreQueue.isEmpty())
    {
      ObjectNode<?> current = toExploreQueue.poll();
      graph.addVertex(current); // in case there are no constituent
      
      List<? extends ConstituentNode<?>> constituents = null;
      ruleApplication : for (ExplorationRule rule : explorationRules)
      {
        constituents = rule.explore(current.object);
        if (constituents != null)
          break ruleApplication;
      }
      if (constituents == null)
        throw new RuntimeException("No rule found to apply to object " + current.object);
      
      for (ConstituentNode<?> constituent : constituents)
      {
        addEdgeAndVertices(current, constituent);
        if (constituent.resolvesToObject()) 
        {
          ObjectNode<?> next = new ObjectNode<>(constituent.resolve());
          if (!graph.vertexSet().contains(next))
            toExploreQueue.add(next);
          addEdgeAndVertices(constituent, next);
        }
      } // of constituent loop
    } // of exploration
  } // of method
  
  public DotExporter<Node, Pair<Node,Node>> toDotExporter()
  {
    DotExporter<Node, Pair<Node,Node>> result = new DotExporter<>(graph);
    result.vertexNameProvider = node -> node.toStringSummary();
    result.addVertexAttribute("shape", node -> "box");
    result.addVertexAttribute("style", node -> node instanceof ConstituentNode<?> ? "dotted" : "plain");
    result.addVertexAttribute("color",     node -> node.isMutable() ? "red" : "black");
    result.addVertexAttribute("fontcolor", node -> node.isMutable() ? "red" : "black");
    return result;
  }
  
  public void exportDot(File file) 
  {
    toDotExporter().export(file);
  }

  public Stream<Node> getAccessibleNodes(Object from)
  {
    return getAccessibleNodes(new ObjectNode<>(from));
  }
  
  public Stream<Node> getAccessibleNodes(Node from)
  {
    return toStream(new BreadthFirstIterator<>(graph, from));
  }
  
  public Stream<Node> getAccessibleNodes()
  {
    return graph.vertexSet().stream();
  }
  
  public static <T> Stream<T> toStream(Iterator<T> iter)
  {
    Iterable<T> iterable = () -> iter;
    return StreamSupport.stream(iterable.spliterator(), false);
  }
}


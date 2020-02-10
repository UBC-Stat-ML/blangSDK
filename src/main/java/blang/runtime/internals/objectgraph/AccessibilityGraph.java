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
  public final LinkedHashSet<Node> roots = new LinkedHashSet<>();
  
  /**
   * Note that in the graph, object nodes points to constituent nodes only. 
   * Constituent nodes always have at most one outgoing edge (zero in the case of primitives), and object nodes can have zero, one, or 
   * more constituents. 
   */
  private void addEdgeAndVertices(ObjectNode<?> objectNode, ConstituentNode<?> constituentNode)
  {
    _addEdgeAndVertices(objectNode, constituentNode);
  }
  
  /**
   * Constituents nodes generally point to ObjectNode, except in the cases where the ObjectNode encapsulates a 
   * ConstituentNode (e.g. for matrix view into a cell).
   */
  private void addEdgeAndVertices(ConstituentNode<?> constituentNode, Node objectNode)
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
  
  public void add(Object object)
  {
    Node root = StaticUtils.node(object);
    roots.add(root);
    
    if (graph.vertexSet().contains(root))
      return; // in case a root is a subset of another
    
    final LinkedList<Node> toExploreQueue = new LinkedList<>();
    toExploreQueue.add(root);
    
    while (!toExploreQueue.isEmpty())
    {
      Node current = toExploreQueue.poll();
      graph.addVertex(current); // in case there are no constituent
      
      if (current instanceof ObjectNode<?>)
      {
        ObjectNode<?> objectNode = (ObjectNode<?>) current;
        List<? extends ConstituentNode<?>> constituents = constituents(objectNode.object);
        for (ConstituentNode<?> constituent : constituents)
        {
          if (!graph.vertexSet().contains(constituent))
            toExploreQueue.add(constituent);
          addEdgeAndVertices(objectNode, constituent);
        }
      }
      else
      {
        ConstituentNode<?> constituent = (ConstituentNode<?>) current;
        if (constituent.resolvesToObject())
        {
          Node next = StaticUtils.node(constituent.resolve());
          if (!graph.vertexSet().contains(next))
            toExploreQueue.add(next);
          addEdgeAndVertices(constituent, next);
        }
      }
    } // of exploration
  } // of method
  
  private List<? extends ConstituentNode<?>> constituents(Object object)
  {
    List<? extends ConstituentNode<?>> constituents = null;
    for (ExplorationRule rule : explorationRules)
    {
      constituents = rule.explore(object);
      if (constituents != null)
        return constituents;
    }
      throw new RuntimeException("No rule found to apply to object " + object);
  }
  
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

  public Stream<Node> getAccessibleNodes(Object object)
  {
    return toStream(new BreadthFirstIterator<>(graph, StaticUtils.node(object)));
  }
  
  public Iterable<Node> iterateAccessibleNodes(Object object)
  {
    return () -> new BreadthFirstIterator<>(graph, StaticUtils.node(object));
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


package blang.runtime.objectgraph;

import java.io.File;
import java.lang.reflect.Field;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.Map;
import java.util.Set;
import java.util.function.Predicate;

import org.jgrapht.DirectedGraph;
import org.jgrapht.UndirectedGraph;
import org.jgrapht.ext.VertexNameProvider;

import com.google.common.collect.LinkedHashMultimap;

import bayonet.graphs.DotExporter;
import bayonet.graphs.GraphUtils;
import blang.core.Factor;
import blang.core.Model;
import blang.core.ModelComponent;
import blang.core.ModelComponents;
import blang.core.Param;
import blang.mcmc.SamplerBuilder;
import blang.runtime.Observations;
import blang.runtime.objectgraph.AccessibilityGraph.Node;
import briefj.ReflexionUtils;
import briefj.collections.UnorderedPair;


/**
 * Low-level analysis of an accessibility graph for the purpose of building a factor graph.
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 *
 */
public class GraphAnalysis
{
  DirectedGraph<ObjectNode<ModelComponent>,?> modelComponentsHierachy;
  AccessibilityGraph accessibilityGraph;
  LinkedHashSet<Node> observedNodesClosure;
  LinkedHashSet<Node> unobservedMutableNodes;
  LinkedHashSet<ObjectNode<?>> latentVariables;
  public LinkedHashSet<ObjectNode<?>> getLatentVariables() {
    return latentVariables;
  }

  LinkedHashMultimap<Node, ObjectNode<Factor>> mutableToFactorCache;
  LinkedHashSet<ObjectNode<Factor>> factorNodes;
  Predicate<Class<?>> isVariablePredicate;
  Map<ObjectNode<ModelComponent>,String> factorDescriptions;
  
  public GraphAnalysis(Model model, Observations observations)
  {
    buildModelComponentsHierarchy(model);
    buildAccessibilityGraph(model);
    
    LinkedHashSet<Node> frozenRoots = buildFrozenRoots(model, observations);
    
    isVariablePredicate = c -> 
      !SamplerBuilder.SAMPLER_PROVIDER_1.getProducts(c).isEmpty() ||
      !SamplerBuilder.SAMPLER_PROVIDER_2.getProducts(c).isEmpty();
    
    // 1- compute the closure of observed variables
    observedNodesClosure = new LinkedHashSet<>();
    observedNodesClosure.addAll(closure(accessibilityGraph.graph, frozenRoots, true));
    
    // 2- find the unobserved mutable nodes
    unobservedMutableNodes = new LinkedHashSet<>();
    accessibilityGraph.getAccessibleNodes()
        .filter(node -> node.isMutable())
        .filter(node -> !observedNodesClosure.contains(node))
        .forEachOrdered(unobservedMutableNodes::add);
    
    // 3- identify the latent variables
    latentVariables = latentVariables(
        accessibilityGraph, 
        unobservedMutableNodes, 
        isVariablePredicate);
    
    // 4- prepare the cache
    mutableToFactorCache = LinkedHashMultimap.create();
    for (ObjectNode<Factor> factorNode : factorNodes) 
      accessibilityGraph.getAccessibleNodes(factorNode)
        .filter(node -> unobservedMutableNodes.contains(node))
        .forEachOrdered(node -> mutableToFactorCache.put(node, factorNode));
    
    // 5- create the directed factor graph and use it to linearize factor order
//    createDirectedFactorGraph();
//    linearization = GraphUtils.linearization(directedFactorGraph).stream().map(node -> node.object).collect(Collectors.toList());
  }
  
  private void buildAccessibilityGraph(Model model) 
  {
    accessibilityGraph = new AccessibilityGraph();
    accessibilityGraph.add(model); 
    for (ObjectNode<Factor> factorNode : factorNodes)
      accessibilityGraph.add(factorNode);
  }

  @SuppressWarnings({ "rawtypes", "unchecked" })
  LinkedHashSet<Node> buildFrozenRoots(Model model, Observations observations) 
  {
    LinkedHashSet<Node> result = new LinkedHashSet<>();
    result.addAll(observations.getObservationRoots());
    // mark params in top level model as frozen
    for (Field f : ReflexionUtils.getDeclaredFields(model.getClass(), true)) 
      if (f.getAnnotation(Param.class) != null) 
        result.add(new ObjectNode(ReflexionUtils.getFieldValue(f, model)));
    
    if (!accessibilityGraph.graph.vertexSet().containsAll(result))
      throw new RuntimeException("Observed variables should be subsets of the accessibility graph");
    
    return result;
  }

  @SuppressWarnings({ "unchecked", "rawtypes" })
  void buildModelComponentsHierarchy(Model model)
  {
    factorDescriptions = new LinkedHashMap<>();
    modelComponentsHierachy = GraphUtils.newDirectedGraph();
    buildModelComponentsHierarchy(model, factorDescriptions, modelComponentsHierachy);
    factorNodes = new LinkedHashSet<>();
    for (ObjectNode<ModelComponent> node : modelComponentsHierachy.vertexSet())
      if (node.object instanceof Factor)
        factorNodes.add((ObjectNode) node);
  }
  
  static void buildModelComponentsHierarchy(
      ModelComponent modelComponent, 
      Map<ObjectNode<ModelComponent>,String> descriptions, 
      DirectedGraph<ObjectNode<ModelComponent>,?> result)
  {
    ObjectNode<ModelComponent> currentNode = new ObjectNode<>(modelComponent);
    result.addVertex(currentNode);
    if (modelComponent instanceof Model)
    {
      Model model = (Model) modelComponent;
      ModelComponents subComponents = model.components();
      for (ModelComponent subComponent : model.components().get())
      {
        ObjectNode<ModelComponent> childNode = new ObjectNode<>(subComponent);
        descriptions.put(childNode, subComponents.description(subComponent));
        buildModelComponentsHierarchy(subComponent, descriptions, result);
        result.addEdge(currentNode, childNode);
      }
    }
  }
  
//  private Optional<List<ForwardSimulator>> createForwardSimulator(Model model)
//  {
//    if (model instanceof ForwardSimulator)
//      return Optional.of(Collections.singletonList((ForwardSimulator) model));
//    
//    DirectedGraph<Model,?> subModels = GraphUtils.newDirectedGraph(); BROKEN, NEED TO KEEP MODEL HIERARCHY
//    for (ObjectNode<Factor> factorNode : factorNodes)
//    {
//      for (Field field : ReflexionUtils.getDeclaredFields(factorNode.object.getClass(), true))
//        if (field.getAnnotation(Param.class) == null)
//        {
//          Object parentVariable = ReflexionUtils.getFieldValue(field, factorNode.object);
//          accessibilityGraph.getAccessibleNodes(parentVariable) // cannot use the cache directly here (this makes this loop a bottleneck)
//            .filter(node -> unobservedMutableNodes.contains(node))
//            .forEachOrdered(node -> {
//              for (ObjectNode<Factor> connectedFactor : mutableToFactorCache.get(node))
//                if (connectedFactor != factorNode)
//                  addDirectedLink(factorNode, connectedFactor);
//            });
//        }
//    }
//    
//  }
  
  /*
   * CHANGE TO:
   * Input:  a Model
   * Output: a sorted list of ForwardSimulator's
   * 
   * Rules: if the Model is a ForwardSimulator, just use that
   * If not, look at list of components, if they are all Models, sort them and recurse, otherwise no gen possible
   * 
   * To sort, use something similar to current, 
   */
//  private void createDirectedFactorGraph() 
//  {
//    directedFactorGraph = GraphUtils.newDirectedGraph();
//    for (ObjectNode<Factor> factorNode : factorNodes)
//    {
//      for (Field field : ReflexionUtils.getDeclaredFields(factorNode.object.getClass(), true))
//        if (field.getAnnotation(Param.class) == null)
//        {
//          Object parentVariable = ReflexionUtils.getFieldValue(field, factorNode.object);
//          accessibilityGraph.getAccessibleNodes(parentVariable) // cannot use the cache directly here (this makes this loop a bottleneck)
//            .filter(node -> unobservedMutableNodes.contains(node))
//            .forEachOrdered(node -> {
//              for (ObjectNode<Factor> connectedFactor : mutableToFactorCache.get(node))
//                if (connectedFactor != factorNode)
//                  addDirectedLink(factorNode, connectedFactor);
//            });
//        }
//    }
//  }

//  private void addDirectedLink(ObjectNode<Factor> f0, ObjectNode<Factor> f1) 
//  {
//    if (!directedFactorGraph.containsVertex(f0)) directedFactorGraph.addVertex(f0);
//    if (!directedFactorGraph.containsVertex(f1)) directedFactorGraph.addVertex(f1);
//    if (!directedFactorGraph.containsEdge(f0, f1))
//      directedFactorGraph.addEdge(f0, f1);
//  }
  
  public void exportAccessibilityGraphVisualization(File file)
  {
    accessibilityGraph.exportDot(file); 
  }
  
  public void exportFactorGraphVisualization(File file) 
  {
    factorGraphVisualization().export(file);
  }
  
  public DotExporter<Node, UnorderedPair<Node, Node>> factorGraphVisualization() 
  {
    return factorGraphVisualization(node -> {
      if (node instanceof ObjectNode) 
      {
        Object o = ((ObjectNode<?>) node).object;
        if (factorDescriptions.containsKey(o))
          return factorDescriptions.get(o);
      }
      return node.toStringSummary();
    });
  }
  
  public DotExporter<Node, UnorderedPair<Node, Node>> factorGraphVisualization(VertexNameProvider<Node> vertexNameProvider)
  {
    UndirectedGraph<Node, UnorderedPair<Node, Node>> factorGraph = GraphUtils.newUndirectedGraph();
    
    // add factors
    for (ObjectNode<? extends Factor> f : factorNodes)
      factorGraph.addVertex(f);
    
    // add latent variables and connect them
    for (ObjectNode<?> l : latentVariables)
    {
      factorGraph.addVertex(l);
      for (Node n : getConnectedFactor(l))
        factorGraph.addEdge(n, l);
    }
    
    DotExporter<Node, UnorderedPair<Node,Node>> result = new DotExporter<>(factorGraph);
    result.vertexNameProvider = vertexNameProvider;
    result.addVertexAttribute("shape", node -> factorNodes.contains(node) ? "box" : "");
    
    return result;
  }
        
  public LinkedHashSet<ObjectNode<Factor>> getConnectedFactor(ObjectNode<?> latentVariable)
  {
    LinkedHashSet<ObjectNode<Factor>> result = new LinkedHashSet<>();
    accessibilityGraph.getAccessibleNodes(latentVariable)
        .filter(node -> unobservedMutableNodes.contains(node))
        .forEachOrdered(node -> result.addAll(mutableToFactorCache.get(node)));
    return result;
  }
  
  public String toStringSummary()
  {
    StringBuilder result = new StringBuilder();
    for (ObjectNode<?> latentVar : latentVariables)
    {
      result.append(latentVar.toStringSummary() + "\n");
      for (ObjectNode<Factor> connectedFactor : getConnectedFactor(latentVar))
        result.append("\t" + connectedFactor.toStringSummary() + "\n");
    }
    return result.toString();
  }
  
  /**
   * A latent variable is an ObjectNode which has:
   * 1. some unobserved mutable nodes under it 
   * 2. AND a class identified to be a variable (i.e. such that samplers can attach to them)
   */
  private static LinkedHashSet<ObjectNode<?>> latentVariables(
      AccessibilityGraph accessibilityGraph,
      final Set<Node> unobservedMutableNodes,
      Predicate<Class<?>> isVariablePredicate
      )
  {
    // find the ObjectNode's which have some unobserved mutable nodes under them
    LinkedHashSet<ObjectNode<?>> ancestorsOfUnobservedMutableNodes = new LinkedHashSet<>();
    closure(accessibilityGraph.graph, unobservedMutableNodes, false).stream()
        .filter(node -> node instanceof ObjectNode<?>)
        .map(node -> (ObjectNode<?>) node)
        .forEachOrdered(ancestorsOfUnobservedMutableNodes::add);
    
    // for efficiency, apply the predicate on the set of the associated classes
    LinkedHashSet<Class<?>> matchedVariableClasses = new LinkedHashSet<>();
    ancestorsOfUnobservedMutableNodes.stream()
      .map(node -> node.object.getClass())
      .filter(isVariablePredicate)
      .forEachOrdered(matchedVariableClasses::add);
    
    // return the ObjectNode's which have some unobserved mutable nodes under them 
    // AND which have a class identified to be a variable (i.e. such that samplers can attach to them)
    LinkedHashSet<ObjectNode<?>> result = new LinkedHashSet<>();
    ancestorsOfUnobservedMutableNodes.stream()
        .filter(node -> matchedVariableClasses.contains(node.object.getClass()))
        .forEachOrdered(result::add);  
    return result;
  }
  
  static <V,E> LinkedHashSet<V> closure(
      DirectedGraph<V, E> graph, 
      final Set<V> generatingSet,
      boolean forward)
  {
    final LinkedHashSet<V> result = new LinkedHashSet<>();
    LinkedList<V> toExploreQueue = new LinkedList<>(generatingSet);
    
    while (!toExploreQueue.isEmpty())
    {
      V current = toExploreQueue.poll();
      result.add(current);
      for (E e : forward ? graph.outgoingEdgesOf(current) : graph.incomingEdgesOf(current))
      {
        V next = forward ? graph.getEdgeTarget(e) : graph.getEdgeSource(e);
        if (!result.contains(next))
          toExploreQueue.add(next);
      }
    }
    
    return result;
  }
}

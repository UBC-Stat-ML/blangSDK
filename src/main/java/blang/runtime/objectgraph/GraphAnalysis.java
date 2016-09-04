package blang.runtime.objectgraph;

import java.io.File;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.Set;
import java.util.function.Predicate;

import org.jgrapht.DirectedGraph;
import org.jgrapht.UndirectedGraph;
import org.jgrapht.ext.VertexNameProvider;

import bayonet.graphs.DotExporter;
import bayonet.graphs.GraphUtils;
import blang.core.Factor;
import blang.mcmc.SamplerBuilder;
import blang.runtime.objectgraph.AccessibilityGraph.Node;
import blang.utils.TypeProvider;
import briefj.BriefCollections;
import briefj.collections.UnorderedPair;

import com.google.common.collect.LinkedHashMultimap;


/**
 * Analysis of an accessibility graph for the purpose of building a factor graph.
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 *
 */
public class GraphAnalysis
{
  
  public static GraphAnalysis create(Inputs inputs)
  {
    GraphAnalysis result = new GraphAnalysis();
    result.accessibilityGraph = inputs.accessibilityGraph;
    result.factorNodes = inputs.factors;
    result.isVariablePredicate = c -> 
      !SamplerBuilder.SAMPLER_PROVIDER_1.getProducts(c).isEmpty() ||
      !SamplerBuilder.SAMPLER_PROVIDER_2.getProducts(c).isEmpty();
    
    if (!inputs.accessibilityGraph.graph.vertexSet().containsAll(inputs.nonRecursiveObservedNodes) ||
        !inputs.accessibilityGraph.graph.vertexSet().containsAll(inputs.recursiveObservedNodes))
      throw new RuntimeException("Observed variables should be subsets of the accessibility graph");
    
    if (BriefCollections.intersects(inputs.nonRecursiveObservedNodes, inputs.recursiveObservedNodes))
      throw new RuntimeException("A variable should be either recursively observable, observable, or neither");
    
    // 1- compute the closure of observed variables
    result.observedNodesClosure = new LinkedHashSet<>();
    result.observedNodesClosure.addAll(inputs.nonRecursiveObservedNodes);
    result.observedNodesClosure.addAll(closure(inputs.accessibilityGraph.graph, inputs.recursiveObservedNodes, true));
    
    // 2- find the unobserved mutable nodes
    result.unobservedMutableNodes = new LinkedHashSet<>();
    inputs.accessibilityGraph.getAccessibleNodes()
        .filter(node -> node.isMutable())
        .filter(node -> !result.observedNodesClosure.contains(node))
        .forEachOrdered(result.unobservedMutableNodes::add);
    
    // 3- identify the latent variables
    result.latentVariables = latentVariables(
        inputs.accessibilityGraph, 
        result.unobservedMutableNodes, 
        result.isVariablePredicate);
    
    // 4- prepare the cache
    result.mutableToFactorCache = LinkedHashMultimap.create();
    for (ObjectNode<Factor> factorNode : inputs.factors) 
      inputs.accessibilityGraph.getAccessibleNodes(factorNode)
        .filter(node -> result.unobservedMutableNodes.contains(node))
        .forEachOrdered(node -> result.mutableToFactorCache.put(node, factorNode));
    
    return result;
  }
  
  public AccessibilityGraph accessibilityGraph;
  public LinkedHashSet<Node> observedNodesClosure;
  public LinkedHashSet<Node> unobservedMutableNodes;
  public LinkedHashSet<ObjectNode<?>> latentVariables;
  private LinkedHashMultimap<Node, ObjectNode<Factor>> mutableToFactorCache;
  public LinkedHashSet<ObjectNode<Factor>> factorNodes;
  public Predicate<Class<?>> isVariablePredicate;
  
  private GraphAnalysis() 
  {
  }
  
//  next: 
//    - instead of a factor graph object, use injections to annotated fields in the sampler?
//    - use dot stuff to create a factor graph viz based on getConnFactor
//    - naming facilities (based on AccessibilityGraph)
//    - mcmc matching (reuse blang2's NodeMoveUtils)
//    - parsing stuff (to make things observed, etc)
//    - question: how to deal with gradients?
//    - need to think about RF vs MH infrastructure
  
  @SuppressWarnings("unchecked")
  public void exportFactorGraphVisualization(File file, 
      @SuppressWarnings("rawtypes") VertexNameProvider /* Type erasure used here to work around some weird bug with xtend (builds fine in eclipse, crashed in gradle with error:
        "The method exportFactorGraphVisualization(File, VertexNameProvider<Object>) from the type GraphAnalysis refers to the missing type Object (file:/Users/bouchard/w/blangSDK/src/main/java/blang/runtime/ModelUtils.xtend line : 62 column : 19)"
       */ vertexNameProvider) 
  {
    factorGraphVisualization(vertexNameProvider).export(file);
  }
  
  public DotExporter<Node, UnorderedPair<Node, Node>> factorGraphVisualization() 
  {
    return factorGraphVisualization(node -> node.toStringSummary());
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
//    {
//      LinkedHashSet<Class<?>> associatedClasses = new LinkedHashSet<>();
//      ancestorsOfUnobservedMutableNodes.stream()
//          .map(node -> node.object.getClass())
//          .forEachOrdered(associatedClasses::add);
//      
//    }
    
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

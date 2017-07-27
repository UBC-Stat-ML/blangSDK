package blang.runtime.objectgraph;

import java.io.File;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Predicate;

import org.jgrapht.DirectedGraph;
import org.jgrapht.UndirectedGraph;
import org.jgrapht.ext.VertexNameProvider;

import com.google.common.collect.LinkedHashMultimap;
import com.google.common.collect.Multimap;
import com.google.common.collect.Multimaps;

import bayonet.graphs.DotExporter;
import bayonet.graphs.GraphUtils;
import blang.core.Factor;
import blang.core.ForwardSimulator;
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
  public LinkedHashSet<ObjectNode<?>> getLatentVariables() 
  {
    return latentVariables;
  }
        
  public LinkedHashSet<ObjectNode<Factor>> getConnectedFactor(ObjectNode<?> latentVariable)
  {
    LinkedHashSet<ObjectNode<Factor>> result = new LinkedHashSet<>();
    accessibilityGraph.getAccessibleNodes(latentVariable)
        .filter(node -> freeMutableNodes.contains(node))
        .forEachOrdered(node -> result.addAll(mutableToFactorCache.get(node)));
    return result;
  }
  
  Model model;
  Multimap<ObjectNode<Model>,ObjectNode<ModelComponent>> model2ModelComponents;
  AccessibilityGraph accessibilityGraph;
  LinkedHashSet<Node> frozenNodesClosure;
  LinkedHashSet<Node> freeMutableNodes;
  LinkedHashSet<ObjectNode<?>> latentVariables;
  LinkedHashMultimap<Node, ObjectNode<Factor>> mutableToFactorCache;
  LinkedHashSet<ObjectNode<Factor>> factorNodes;
  Predicate<Class<?>> isVariablePredicate;
  Map<ObjectNode<ModelComponent>,String> factorDescriptions;
  
  public GraphAnalysis(Model model, Observations observations)
  {
    this.model = model;
    buildModelComponentsHierarchy();
    buildAccessibilityGraph();
    
    // frozen variables are either observed or the top level param's
    LinkedHashSet<Node> frozenRoots = buildFrozenRoots(model, observations);
    
    isVariablePredicate = c -> 
      !SamplerBuilder.SAMPLER_PROVIDER_1.getProducts(c).isEmpty() ||
      !SamplerBuilder.SAMPLER_PROVIDER_2.getProducts(c).isEmpty();
    
    // 1- compute the closure of the frozen variables
    frozenNodesClosure = new LinkedHashSet<>();
    frozenNodesClosure.addAll(closure(accessibilityGraph.graph, frozenRoots, true));
    
    // 2- find the free mutable nodes, i.e. those mutable (i.e. non-final fields, array entries, etc)  and not frozen
    freeMutableNodes = new LinkedHashSet<>();
    accessibilityGraph.getAccessibleNodes()
        .filter(node -> node.isMutable())
        .filter(node -> !frozenNodesClosure.contains(node))
        .forEachOrdered(freeMutableNodes::add);
    
    // 3- identify the latent variables
    latentVariables = latentVariables(
        accessibilityGraph, 
        freeMutableNodes, 
        isVariablePredicate);
    
    // 4- prepare the cache
    mutableToFactorCache = LinkedHashMultimap.create();
    for (ObjectNode<Factor> factorNode : factorNodes) 
      accessibilityGraph.getAccessibleNodes(factorNode)
        .filter(node -> freeMutableNodes.contains(node))
        .forEachOrdered(node -> mutableToFactorCache.put(node, factorNode));
    
    // 5- create the directed factor graph and use it to linearize factor order
//    createDirectedFactorGraph();
//    linearization = GraphUtils.linearization(directedFactorGraph).stream().map(node -> node.object).collect(Collectors.toList());
  }
  
  void buildAccessibilityGraph() 
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

  @SuppressWarnings({ "rawtypes", "unchecked" })
  void buildModelComponentsHierarchy()
  {
    factorDescriptions = new LinkedHashMap<>();
    model2ModelComponents = Multimaps.newMultimap(new LinkedHashMap<>(), () -> new LinkedHashSet<>());
    buildModelComponentsHierarchy(model);
    factorNodes = new LinkedHashSet<>();
    for (ObjectNode<ModelComponent> node : model2ModelComponents.values())
      if (node.object instanceof Factor)
        factorNodes.add((ObjectNode) node);
  }
  
  @SuppressWarnings("unchecked")
  void buildModelComponentsHierarchy(
      ModelComponent modelComponent)
  {
    @SuppressWarnings("rawtypes")
    ObjectNode currentNode = new ObjectNode<>(modelComponent);
    if (modelComponent instanceof Model)
    {
      Model model = (Model) modelComponent;
      ModelComponents subComponents = model.components();
      for (ModelComponent subComponent : model.components().get())
      {
        ObjectNode<ModelComponent> childNode = new ObjectNode<>(subComponent);
        factorDescriptions.put(childNode, subComponents.description(subComponent));
        buildModelComponentsHierarchy(subComponent);
        model2ModelComponents.put(currentNode, childNode);
      }
    }
  }
  
  public List<ForwardSimulator> createForwardSimulator()
  {
    return createForwardSimulator(model);
  }
  
  @SuppressWarnings("unchecked")
  private List<ForwardSimulator> createForwardSimulator(Model model)
  {
    if (model instanceof ForwardSimulator)
      return Collections.singletonList((ForwardSimulator) model);
    
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    DirectedGraph<Node,?> graph = GraphUtils.newDirectedGraph(); 
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      ModelComponent component = componentNode.object;
      if (!(component instanceof Model))
        throw new RuntimeException("If a Model is not a ForwardSimulator, all its components should be Model's, no Factor's allowed");
      
      for (Field field : ReflexionUtils.getDeclaredFields(component.getClass(), true))
      {
        boolean isParam = field.getAnnotation(Param.class) != null;
        Object dependencyRoot = ReflexionUtils.getFieldValue(field, component);
        accessibilityGraph.getAccessibleNodes(dependencyRoot)
          .filter(node -> freeMutableNodes.contains(node))
          .forEachOrdered(node -> graph.addEdge(
              isParam ? node          : componentNode, 
              isParam ? componentNode : node));
      }
    }
    List<ForwardSimulator> result = new ArrayList<>();
    List<Node> linearization = GraphUtils.linearization(graph);
    for (Node node : linearization)
      if (model2ModelComponents.get(modelNode).contains(node))
        result.addAll(createForwardSimulator((Model) ((ObjectNode<Model>) node).object));
    
    return result;  
  }
 
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
   * 1. some free mutable nodes under it 
   * 2. AND a class identified to be a variable (i.e. such that samplers can attach to them)
   */
  private static LinkedHashSet<ObjectNode<?>> latentVariables(
      AccessibilityGraph accessibilityGraph,
      final Set<Node> freeMutableNodes,
      Predicate<Class<?>> isVariablePredicate
      )
  {
    // find the ObjectNode's which have some unobserved mutable nodes under them
    LinkedHashSet<ObjectNode<?>> ancestorsOfUnobservedMutableNodes = new LinkedHashSet<>();
    closure(accessibilityGraph.graph, freeMutableNodes, false).stream()
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

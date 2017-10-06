package blang.runtime.internals.objectgraph;

import java.io.File;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
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
import blang.core.AnnealedFactor;
import blang.core.Factor;
import blang.core.ForwardSimulator;
import blang.core.LogScaleFactor;
import blang.core.Model;
import blang.core.ModelComponent;
import blang.core.Param;
import blang.mcmc.internals.ExponentiatedFactor;
import blang.mcmc.internals.SamplerBuilder;
import blang.runtime.Observations;
import blang.types.RealScalar;
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
  public final Model model;
  private Multimap<ObjectNode<Model>,ObjectNode<ModelComponent>> model2ModelComponents;
  private AccessibilityGraph accessibilityGraph;
  private final LinkedHashSet<Node> frozenNodesClosure;
  private final LinkedHashSet<Node> freeMutableNodes;
  private final LinkedHashSet<ObjectNode<?>> latentVariables;
  private final LinkedHashMultimap<Node, ObjectNode<Factor>> mutableToFactorCache;
  private final LinkedHashSet<ObjectNode<Factor>> factorNodes = new LinkedHashSet<>();
  private final Predicate<Class<?>> isVariablePredicate;
  private final Map<ObjectNode<ModelComponent>,String> factorDescriptions = new LinkedHashMap<>();
  private final Observations observations;
  private final RealScalar annealingParameter = new RealScalar(1.0);
  
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
  
  public boolean hasObservations()
  {
    return !observations.getObservationRoots().isEmpty();
  }
  
  public List<ForwardSimulator> createForwardSimulator()
  {
    return createForwardSimulator(model);
  }
  
  /**
   * Anneal only the factors emitting observed values.
   * 
   * @return (set of annealed factors, set of non-annealed (fixed) factors)
   */
  public AnnealingStructure createLikelihoodAnnealer()
  {
    List<AnnealedFactor> annealedFactors = new ArrayList<>(); 
    List<Factor> fixedFactors = new ArrayList<>(); 
    createLikelihoodAnnealer(model, annealedFactors, fixedFactors);
    
    AnnealingStructure result = new AnnealingStructure(annealingParameter);
    for (AnnealedFactor annealed : annealedFactors)
    {
      annealed.setAnnealingParameter(annealingParameter); 
      if (annealed instanceof ExponentiatedFactor)
        result.exponentiatedFactors.add((ExponentiatedFactor) annealed);
      else
        result.otherAnnealedFactors.add(annealed);
    }
    for (Factor fixed : fixedFactors)
    {
      if (fixed instanceof LogScaleFactor)
        result.fixedLogScaleFactors.add((LogScaleFactor) fixed);
      else
        result.otherFixedFactors.add(fixed);
    }
    return result;
  }
  
  public GraphAnalysis(Model model, Observations observations)
  {
    this.model = model;
    this.observations = observations;
    
    // 0- setup first layer of data structures
    buildModelComponentsHierarchy(true);
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
  }
  
  private void buildAccessibilityGraph() 
  {
    accessibilityGraph = new AccessibilityGraph();
    accessibilityGraph.add(model); 
    for (ObjectNode<Factor> factorNode : factorNodes)
      accessibilityGraph.add(factorNode);
  }

  @SuppressWarnings({ "rawtypes", "unchecked" })
  private LinkedHashSet<Node> buildFrozenRoots(Model model, Observations observations) 
  {
    LinkedHashSet<Node> result = new LinkedHashSet<>();
    result.addAll(observations.getObservationRoots());
    // mark params in top level model as frozen
    for (Field f : ReflexionUtils.getDeclaredFields(model.getClass(), true)) 
      if (f.getAnnotation(Param.class) != null) 
        result.add(new ObjectNode(ReflexionUtils.getFieldValue(f, model)));
    
    if (!accessibilityGraph.graph.vertexSet().containsAll(result))
    {
      LinkedHashSet<Node> copy = new LinkedHashSet<>(result);
      copy.removeAll(accessibilityGraph.graph.vertexSet());
      throw new RuntimeException("Observed variables should be subsets of the accessibility graph: " + copy);
    }
    
    return result;
  }

  @SuppressWarnings({ "rawtypes", "unchecked" })
  private void buildModelComponentsHierarchy(boolean wrapInAnnealableFactors)
  {
    model2ModelComponents = Multimaps.newMultimap(new LinkedHashMap<>(), () -> new LinkedHashSet<>());
    buildModelComponentsHierarchy(model, wrapInAnnealableFactors);
    for (ObjectNode<ModelComponent> node : model2ModelComponents.values())
      if (node.object instanceof Factor)
        factorNodes.add((ObjectNode) node);
  }
  
  @SuppressWarnings("unchecked")
  private void buildModelComponentsHierarchy(
      ModelComponent modelComponent, boolean wrapInAnnealableFactors)
  {
    @SuppressWarnings("rawtypes")
    ObjectNode currentNode = new ObjectNode<>(modelComponent);
    if (modelComponent instanceof Model)
    {
      Model model = (Model) modelComponent;
      Collection<ModelComponent> subComponents = model.components();
      for (ModelComponent subComponent : subComponents)
      {
        String description = subComponent.toString();
        if (   wrapInAnnealableFactors  // we asked to wrap things in annealers
            && subComponent instanceof LogScaleFactor  // and it's numeric (not a constraint-based factor)
            && !(subComponent instanceof AnnealedFactor))  // and it's not already annealed via custom mechanism
          subComponent = new ExponentiatedFactor((LogScaleFactor) subComponent);
        ObjectNode<ModelComponent> childNode = new ObjectNode<>(subComponent);
        if (subComponent instanceof Factor)
          factorDescriptions.put(childNode, description);
        buildModelComponentsHierarchy(subComponent, wrapInAnnealableFactors);
        model2ModelComponents.put(currentNode, childNode);
      }
    }
  }
  
  private void createLikelihoodAnnealer(Model model, List<AnnealedFactor> annealedFactors, List<Factor> fixedFactors)
  {
    if (model instanceof ForwardSimulator)
    {
      if (allRandomNodesObserved(model))
        addAllRecursively(model, annealedFactors); 
      else
        addAllRecursively(model, fixedFactors); 
      return;
    }
    
    // recurse
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      ModelComponent component = componentNode.object;
      if (!(component instanceof Model))
        throw new RuntimeException("If a Model is not a ForwardSimulator, all its components should be Model's, no Factor's allowed");
      Model submodel = (Model) component;
      createLikelihoodAnnealer(submodel, annealedFactors, fixedFactors);
    }
  }
  
  @SuppressWarnings("unchecked")
  private <T> void addAllRecursively(Model model, List<T> factors)
  {
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      ModelComponent component = componentNode.object;
      if (component instanceof Model)
        addAllRecursively((Model) component, factors);
      else
        factors.add((T) component);
    }
  }
  
  @SuppressWarnings("unchecked")
  private List<ForwardSimulator> createForwardSimulator(Model model)
  {
    if (model instanceof ForwardSimulator)
    {
      if (allRandomNodesObserved(model))
        return Collections.emptyList();
      else
        return Collections.singletonList((ForwardSimulator) model);
    }
    
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    DirectedGraph<Node,?> graph = GraphUtils.newDirectedGraph(); // a bipartite graph over the children componentNodes and their fields
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      graph.addVertex(componentNode);
      
      ModelComponent component = componentNode.object;
      if (!(component instanceof Model))
        throw new RuntimeException(model.getClass().getSimpleName() + ": If a Model is not a ForwardSimulator, all its components should be Model's, no Factor's allowed");
      
      for (Field field : ReflexionUtils.getDeclaredFields(component.getClass(), true))
      {
        boolean isParam = field.getAnnotation(Param.class) != null;
        Object dependencyRoot = ReflexionUtils.getFieldValue(field, component);
        accessibilityGraph.getAccessibleNodes(dependencyRoot)
          .filter(node -> freeMutableNodes.contains(node))
          .forEachOrdered(node -> {
            graph.addVertex(node);
            graph.addEdge(
              isParam ? node          : componentNode, 
              isParam ? componentNode : node);
            });
      }
    }
    List<ForwardSimulator> result = new ArrayList<>();
    List<Node> linearization = GraphUtils.linearization(graph);
    for (Node node : linearization)
      if (model2ModelComponents.get(modelNode).contains(node)) // recall that the graph is bipartite (see above)
        result.addAll(createForwardSimulator((Model) ((ObjectNode<Model>) node).object));
    
    return result;  
  }
 
  private boolean allRandomNodesObserved(Model model) 
  {
    Boolean result = null;
    for (Field f : ReflexionUtils.getDeclaredFields(model.getClass(), true))
      if (f.getAnnotation(Param.class) == null) 
      {
        Object randomVariable = ReflexionUtils.getFieldValue(f, model);
        // check that all accessible mutables are unobserved
        boolean hasNoObservedChildren = accessibilityGraph.getAccessibleNodes(randomVariable).filter(current -> current.isMutable()).noneMatch(current -> frozenNodesClosure.contains(current));
        if (result == null)
          result = !hasNoObservedChildren;
        if (result.booleanValue() != !hasNoObservedChildren)
          throw new RuntimeException("For forward simulation, the random variable of all sub models should all be observed or all unobserved.");
      }
    if (result == null)
      return false;
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

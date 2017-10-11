package blang.runtime.internals.objectgraph;

import java.io.File;
import java.io.PrintWriter;
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

import org.apache.commons.lang3.tuple.Pair;
import org.jgrapht.DirectedGraph;
import org.jgrapht.UndirectedGraph;
import org.jgrapht.alg.CycleDetector;
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
import blang.core.SupportFactor;
import blang.mcmc.internals.ExponentiatedFactor;
import blang.mcmc.internals.SamplerBuilder;
import blang.runtime.Observations;
import blang.types.RealScalar;
import briefj.BriefIO;
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
  private final Predicate<Class<?>> isVariablePredicate = c -> 
    !SamplerBuilder.SAMPLER_PROVIDER_1.getProducts(c).isEmpty() ||
    !SamplerBuilder.SAMPLER_PROVIDER_2.getProducts(c).isEmpty();
  private final Map<ObjectNode<ModelComponent>,String> factorDescriptions = new LinkedHashMap<>();
  private final Observations observations;
  private final RealScalar annealingParameter = new RealScalar(1.0);
  private final boolean wrapInAnnealableFactors = true;
  private final boolean wrapInSafeFactor = true;
  
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
  
  public LinkedHashSet<Node> getFreeMutableNodes(ObjectNode<?> root)
  {
    LinkedHashSet<Node> result = new LinkedHashSet<>();
    accessibilityGraph.getAccessibleNodes(root)
      .filter(node -> freeMutableNodes.contains(node)).forEachOrdered(result::add);
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
    
    // setup first layer of data structures
    buildModelComponentsHierarchy();
    buildAccessibilityGraph();
    
    // frozen variables are either observed or the top level param's
    LinkedHashSet<Node> frozenRoots = buildFrozenRoots(model, observations);
    
    // compute the closure of the frozen variables
    frozenNodesClosure = new LinkedHashSet<>();
    frozenNodesClosure.addAll(closure(accessibilityGraph.graph, frozenRoots, true));
    
    // find the free mutable nodes, i.e. those mutable (i.e. non-final fields, array entries, etc)  and not frozen
    freeMutableNodes = new LinkedHashSet<>();
    accessibilityGraph.getAccessibleNodes()
        .filter(node -> node.isMutable())
        .filter(node -> !frozenNodesClosure.contains(node))
        .forEachOrdered(freeMutableNodes::add);
    
    // identify the latent variables (those with specified samplers and free mutable nodes under)
    latentVariables = latentVariables(
        accessibilityGraph, 
        freeMutableNodes, 
        isVariablePredicate);
    
    // prepare the cache mutable -> factors having access to it
    mutableToFactorCache = LinkedHashMultimap.create();
    for (ObjectNode<Factor> factorNode : factorNodes) 
      accessibilityGraph.getAccessibleNodes(factorNode)
        .filter(node -> freeMutableNodes.contains(node))
        .forEachOrdered(node -> mutableToFactorCache.put(node, factorNode));
    
    if (wrapInSafeFactor)
      initializeSafeFactors();
  }
  
  private void initializeSafeFactors() 
  {
    for (ObjectNode<Factor> factorNode : factorNodes)
    {
      Factor factor = factorNode.object;
      SafeFactor safe = getSafeFactor(factor);
      if (safe != null)
      {
        Set<ObjectNode<SupportFactor>> supports = new LinkedHashSet<>();
        Set<Node> accessibilityConstraint = getFreeMutableNodes(factorNode);
        
        for (Node node : accessibilityConstraint)
        {
          Set<ObjectNode<Factor>> candidates = mutableToFactorCache.get(node);
          for (ObjectNode<Factor> candidateNode : candidates)
          {
            SupportFactor candidate = getSupportFactor(candidateNode.object);
            if (candidate != null && accessibilityConstraint.containsAll(getFreeMutableNodes(candidateNode))) // the only one allowed is the exponent dependency
              supports.add(new ObjectNode<SupportFactor>(candidate));
          }
        }
        for (ObjectNode<SupportFactor> supportNode : supports)
          safe.preconditions.add(supportNode.object);
      }
    }
  }

  private SupportFactor getSupportFactor(Factor factor) 
  {
    if (factor instanceof SupportFactor)
      return (SupportFactor) factor;
    if (factor instanceof ExponentiatedFactor)
      return getSupportFactor(((ExponentiatedFactor) factor).enclosed);
    if (factor instanceof SafeFactor)
      return getSupportFactor(((SafeFactor) factor).enclosed);
    return null;
  }

  private SafeFactor getSafeFactor(Factor factor) 
  {
    if (factor instanceof SafeFactor)
      return (SafeFactor) factor;
    if (factor instanceof ExponentiatedFactor)
      return getSafeFactor(((ExponentiatedFactor) factor).enclosed);
    return null;
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
  private void buildModelComponentsHierarchy()
  {
    model2ModelComponents = Multimaps.newMultimap(new LinkedHashMap<>(), () -> new LinkedHashSet<>());
    buildModelComponentsHierarchy(model);
    for (ObjectNode<ModelComponent> node : model2ModelComponents.values())
      if (node.object instanceof Factor)
        factorNodes.add((ObjectNode) node);
  }
  
  @SuppressWarnings("unchecked")
  private void buildModelComponentsHierarchy(
      ModelComponent modelComponent)
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
        boolean isLogScale = subComponent instanceof LogScaleFactor;
        boolean isCustomAnneal = subComponent instanceof AnnealedFactor;
        if (wrapInSafeFactor && isLogScale && !(subComponent instanceof SupportFactor))
          subComponent = new SafeFactor((LogScaleFactor) subComponent);
        if (   wrapInAnnealableFactors  // we asked to wrap things in annealers
            && isLogScale  // and it's numeric (not a measure-zero constraint-based factor)
            && !isCustomAnneal)  // and it's not already annealed via custom mechanism
          subComponent = new ExponentiatedFactor((LogScaleFactor) subComponent);
        ObjectNode<ModelComponent> childNode = new ObjectNode<>(subComponent);
        if (subComponent instanceof Factor)
          factorDescriptions.put(childNode, description);
        buildModelComponentsHierarchy(subComponent);
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
  
  public void checkDAG()
  {
    for (ObjectNode<Model> model : model2ModelComponents.keySet())
      checkDAG(model.object);
  }
  
  private void checkDAG(Model model) 
  {
    boolean allComponentsAreFactor = true;
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    loop : for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
      if (!(componentNode.object instanceof Factor))
      {
        allComponentsAreFactor = false;
        break loop;
      }
    if (allComponentsAreFactor)
      return;
    DirectedGraph<Node, ?> directedGraph = null;
    try { directedGraph = directedGraph(model); }
    catch (NotAllComponentsAreModels nacam) { throw new RuntimeException(model.getClass().getSimpleName() + ": cannot be checked for DAG status as its components contains a mix of factors and models"); }
    
    CycleDetector<Node, ?> cycleDetector = new CycleDetector<>(directedGraph);
    if (cycleDetector.detectCycles())
      throw new RuntimeException("Cycle detected in " + model.getClass().getSimpleName());
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
    
    DirectedGraph<Node,?> graph = null;
    try { graph = directedGraph(model); }
    catch (NotAllComponentsAreModels nacam) { throw new RuntimeException(model.getClass().getSimpleName() + ": If a Model is not a ForwardSimulator, all its components should be Model's, no Factor's allowed"); }
    List<ForwardSimulator> result = new ArrayList<>();
    List<Node> linearization = GraphUtils.linearization(graph);
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    for (Node node : linearization)
      if (model2ModelComponents.get(modelNode).contains(node)) // recall that the graph is bipartite (see above)
        result.addAll(createForwardSimulator((Model) ((ObjectNode<Model>) node).object));
    
    return result;  
  }
  
  @SuppressWarnings("serial")
  private static class NotAllComponentsAreModels extends RuntimeException {}
 
  /**
   * Create a directed bipartite graph between the free mutable nodes and the components. 
   * 
   * Assume all the components of the Model provided are themselves Model's
   * 
   * Also check each random variable is exactly once at the RHS of a ~ statement.
   */
  private DirectedGraph<Node, ?> directedGraph(Model model) 
  {
    Set<ObjectNode<?>> generatedRandomVariables = new LinkedHashSet<>();
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    DirectedGraph<Node, ?> graph = GraphUtils.newDirectedGraph(); // a bipartite graph over the children componentNodes and their fields
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      graph.addVertex(componentNode);
      
      ModelComponent component = componentNode.object;
      if (!(component instanceof Model))
        throw new NotAllComponentsAreModels();
      
      for (Field field : ReflexionUtils.getDeclaredFields(component.getClass(), true))
      {
        boolean isParam = field.getAnnotation(Param.class) != null;
        Object dependencyRoot = ReflexionUtils.getFieldValue(field, component);
        if (!isParam) 
        {
          ObjectNode<?> randomVariableNode = new ObjectNode<>(dependencyRoot);
          if (generatedRandomVariables.contains(randomVariableNode)) 
            throw new RuntimeException("The component " + component.getClass().getSimpleName() + " generated a random variable that already had a distribution");
          generatedRandomVariables.add(randomVariableNode);
        }
        accessibilityGraph.getAccessibleNodes(dependencyRoot)
          .filter(node -> freeMutableNodes.contains(node))
          .forEachOrdered((Node node) -> {
            graph.addVertex(node);
            graph.addEdge(
              isParam ? node          : componentNode, 
              isParam ? componentNode : node);
            });
      }
    }
    if (!generatedRandomVariables.equals(allRandomVariableNodes(model)))
      throw new RuntimeException("Not all random variables were provided with a distribution in " + model.getClass().getSimpleName());
    return graph;
  }

  private Object allRandomVariableNodes(Model model) 
  {
    Set<ObjectNode<?>> result = new LinkedHashSet<>();
    for (Field field : ReflexionUtils.getDeclaredFields(model.getClass(), true))
    {
      boolean isParam = field.getAnnotation(Param.class) != null;
      Object dependencyRoot = ReflexionUtils.getFieldValue(field, model);
      ObjectNode<?> randomVariableNode = new ObjectNode<>(dependencyRoot);
      if (isParam)
        result.add(randomVariableNode);
    }
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
    DotExporter<Node, Pair<Node, Node>> dotExporter = accessibilityGraph.toDotExporter();
    dotExporter.addVertexAttribute("fillcolor", node -> frozenNodesClosure.contains(node) ? "grey" : ""); 
    dotExporter.export(file);
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

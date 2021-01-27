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
import blang.mcmc.internals.ExponentiatedFactor;
import blang.runtime.Observations;
import blang.types.AnnealingParameter;
import blang.types.internals.RealScalar;
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
  public AccessibilityGraph accessibilityGraph;
  private final LinkedHashSet<Node> frozenNodesClosure;
  private final LinkedHashSet<Node> freeMutableNodes;
  private final LinkedHashSet<Node> latentVariables;
  private final LinkedHashMultimap<Node, ObjectNode<Factor>> mutableToFactorCache;
  private final LinkedHashSet<ObjectNode<Factor>> factorNodes = new LinkedHashSet<>(); // all of them, not just LogScale
  
  private final Map<ObjectNode<ModelComponent>,String> factorDescriptions = new LinkedHashMap<>();
  public final RealScalar annealingParameter = new RealScalar(1.0);
  public final boolean treatNaNAsNegativeInfinity;
  public final boolean annealSupport;
  
  public LinkedHashSet<Node> getLatentVariables() 
  {
    return latentVariables;
  }
        
  public LinkedHashSet<ObjectNode<Factor>> getConnectedFactor(Node latentVariable)
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
    AnnealingStructure result = new AnnealingStructure(annealingParameter);
    createLikelihoodAnnealer(model, result);
    return result;
  }
  
  public AnnealingStructure noAnnealer()
  {
    AnnealingStructure result = new AnnealingStructure(null);
    for (ObjectNode<Factor> node : factorNodes)
      if (node.object instanceof LogScaleFactor)
        result.fixedLogScaleFactors.add((LogScaleFactor) node.object);
      else
        result.otherFactors.add(node.object);
    return result;
  }
  
  public GraphAnalysis(Model model)
  {
    this (model, new Observations());
  }
  
  public GraphAnalysis(Model model, Observations observations) 
  {
    this (model, observations, false, true);
  }
  
  public GraphAnalysis(Model model, Observations observations, boolean treatNaNAsNegativeInfinity, boolean annealSupport)
  {
    this.treatNaNAsNegativeInfinity = treatNaNAsNegativeInfinity;
    this.annealSupport = annealSupport;
    this.model = model;
    
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
        freeMutableNodes);
    
    // prepare the cache mutable -> factors having access to it
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
    for (ObjectNode<Model> modelNode : model2ModelComponents.keySet())
      accessibilityGraph.add(modelNode);
  }

  private LinkedHashSet<Node> buildFrozenRoots(Model model, Observations observations) 
  {
    LinkedHashSet<Node> result = new LinkedHashSet<>();
    result.addAll(observations.getObservationRoots());
    
    // verify all nodes that were marked observed are indeed in the accessibility graph
    if (!accessibilityGraph.graph.vertexSet().containsAll(result))
    {
      // if not, prepare a friendly error message identifying culpits
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
        
        // deprecate this: seems unnecessary to create new language construct?
        boolean isCustomAnneal = subComponent instanceof AnnealedFactor;
        
        if (isLogScale  // if it's numeric (not a measure-zero constraint-based factor)
            && !isCustomAnneal)  // and it's not already annealed via custom mechanism
          subComponent = new ExponentiatedFactor((LogScaleFactor) subComponent, treatNaNAsNegativeInfinity, annealSupport);
        ObjectNode<ModelComponent> childNode = new ObjectNode<>(subComponent);
        if (subComponent instanceof Factor)
          factorDescriptions.put(childNode, description);
        buildModelComponentsHierarchy(subComponent);
        model2ModelComponents.put(currentNode, childNode);
      }
    }
  }
  
  private boolean findAndInitAnnealingParam(Factor f, AnnealingStructure annealingStructure) {
    boolean foundAnnealingParamAccess = false;
    for (Node node : accessibilityGraph.iterateAccessibleNodes(f)) {
      if (node instanceof ObjectNode) {
        ObjectNode<?> objectNode = (ObjectNode<?>) node;
        if (objectNode.object instanceof AnnealingParameter) {
          AnnealingParameter param = (AnnealingParameter) objectNode.object;
          foundAnnealingParamAccess = true;
          param._set(annealingStructure.annealingParameter);
        }
      }
    }
    return foundAnnealingParamAccess;
  }
  
  private void createLikelihoodAnnealer(Model model, AnnealingStructure annealingStructure)
  {
    if (model instanceof ForwardSimulator)
    {
      boolean allRandomNodesObserved = allRandomNodesObserved(model);
      for (Factor f : factorsDefinedBy((Model) model))
        if (f instanceof LogScaleFactor)
        {
          boolean foundAnnealingParamAccess = findAndInitAnnealingParam(f, annealingStructure);
          
          if (allRandomNodesObserved || foundAnnealingParamAccess)
          {
            if (f instanceof ExponentiatedFactor)
            {
              ExponentiatedFactor expFactor = (ExponentiatedFactor) f;
              if (foundAnnealingParamAccess) {
                annealingStructure.otherAnnealedFactors.add(expFactor);
              } else {
                ((ExponentiatedFactor) f).setAnnealingParameter(annealingStructure.annealingParameter);
                annealingStructure.exponentiatedFactors.add(expFactor);
              }
            }
            else {
              throw new RuntimeException("Deprecated");
              // annealingStructure.otherAnnealedFactors.add((AnnealedFactor) f);
            }
          }
          else
            annealingStructure.fixedLogScaleFactors.add((LogScaleFactor) f);
        }
        else
          annealingStructure.otherFactors.add(f);
    }
    else
    {
      // recurse
      ObjectNode<Model> modelNode = new ObjectNode<>(model);
      for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
      {
        ModelComponent component = componentNode.object;
        if (!(component instanceof Model))
          throw new RuntimeException("If a Model is not a ForwardSimulator, all its components should be Model's, no Factor's allowed");
        Model submodel = (Model) component;
        createLikelihoodAnnealer(submodel, annealingStructure);
      }
    }
  }
  
  public List<Factor> factorsDefinedBy(Model model)
  {
    List<Factor> result = new ArrayList<>();
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      ModelComponent component = componentNode.object;
      if (component instanceof Model)
        result.addAll(factorsDefinedBy((Model) component));
      else if (component instanceof Factor)
        result.add((Factor) component);
    }
    return result;
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
    Set<Node> generatedRandomVariables = new LinkedHashSet<>();
    ObjectNode<Model> modelNode = new ObjectNode<>(model);
    DirectedGraph<Node, ?> graph = GraphUtils.newDirectedGraph(); // a bipartite graph over the children componentNodes and their fields
    for (ObjectNode<ModelComponent> componentNode : model2ModelComponents.get(modelNode))
    {
      graph.addVertex(componentNode);
      
      ModelComponent component = componentNode.object;
      if (!(component instanceof Model))
        throw new NotAllComponentsAreModels();
      
      for (Field field : StaticUtils.getDeclaredFields(component.getClass()))
      {
        boolean isParam = field.getAnnotation(Param.class) != null;
        Object dependencyRoot = ReflexionUtils.getFieldValue(field, component);
        if (!isParam) 
        {
          Node randomVariableNode = StaticUtils.node(dependencyRoot); 
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
    return graph;
  }

  private boolean allRandomNodesObserved(Model model) 
  {
    Boolean result = null;
    for (Field f : StaticUtils.getDeclaredFields(model.getClass()))
      if (f.getAnnotation(Param.class) == null) 
      {
        Object randomVariable = ReflexionUtils.getFieldValue(f, model); 
        // check that all accessible mutables are unobserved
        boolean hasNoObservedChildren = 
            accessibilityGraph
              .getAccessibleNodes(randomVariable)
              .filter(current -> current.isMutable() && !frozenNodesClosure.contains(current))
              .findAny().isPresent();
        if (result == null)
          result = !hasNoObservedChildren;
        if (result.booleanValue() != !hasNoObservedChildren)
          throw new RuntimeException("For forward simulation, the random variable of all sub models should all be observed or all unobserved.");
      }
    if (result == null)
      return true;
    return result;
  }
  
  public boolean hasAccessibleLatentVariables(Object object)
  {
    return accessibilityGraph
      .getAccessibleNodes(object)
      .filter(current -> latentVariables.contains(current))
      .findAny().isPresent();
  }

  public void exportAccessibilityGraphVisualization(File file)
  {
    DotExporter<Node, Pair<Node, Node>> dotExporter = accessibilityGraph.toDotExporter();
    dotExporter.addVertexAttribute("fillcolor", node -> {
      if (latentVariables.contains(node)) return "yellow"; 
      if (frozenNodesClosure.contains(node)) return "grey"; 
      return "";
    }); 
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
    for (Node l : latentVariables)
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
    for (Node latentVar : latentVariables)
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
  private static LinkedHashSet<Node> latentVariables(
      AccessibilityGraph accessibilityGraph,
      final Set<Node> freeMutableNodes
      )
  {
    // find the ObjectNode's which have some unobserved mutable nodes under them
    LinkedHashSet<Node> ancestorsOfUnobservedMutableNodes = closure(accessibilityGraph.graph, freeMutableNodes, false);
    
    // for efficiency, apply the predicate on the set of the associated classes
    LinkedHashSet<Class<?>> matchedVariableClasses = new LinkedHashSet<>();
    ancestorsOfUnobservedMutableNodes.stream()
      .map(GraphAnalysis::getLatentClass)
      .filter(VariableUtils::isVariable)
      .forEachOrdered(matchedVariableClasses::add);
    
    // return the ObjectNode's which have some unobserved mutable nodes under them 
    // AND which have a class identified to be a variable (i.e. such that samplers can attach to them)
    LinkedHashSet<Node> result = new LinkedHashSet<>();
    ancestorsOfUnobservedMutableNodes.stream()
        .filter(node -> matchedVariableClasses.contains(getLatentClass(node)))
        .forEachOrdered(result::add);  
    return result;
  }
  
  private static Class<?> getLatentClass(Node node)
  {
    return getLatentObject(node).getClass();
  }
  
  public static Object getLatentObject(Node node)
  {
    return node instanceof ObjectNode<?> ? ((ObjectNode<?>) node).object : node;
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

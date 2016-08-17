package blang.runtime.objectgraph;

import java.util.LinkedHashSet;

import blang.core.Factor;
import blang.mcmc.Operator;
import blang.mcmc.Samplers;
import blang.runtime.objectgraph.AccessibilityGraph.Node;
import blang.utils.RecursiveAnnotationProducer;
import blang.utils.TypeProvider;

public class Inputs {
  public final AccessibilityGraph accessibilityGraph = new AccessibilityGraph();
  final LinkedHashSet<Node> 
    nonRecursiveObservedNodes = new LinkedHashSet<>(), 
    recursiveObservedNodes = new LinkedHashSet<>();
  
  final LinkedHashSet<ObjectNode<Factor>> factors = new LinkedHashSet<>();
  
  public final TypeProvider<Class<? extends Operator>> typeProvider = RecursiveAnnotationProducer.ofClasses(Samplers.class, true);
  
  public void markAsObserved(Object object, boolean recursively) {
    final Node newNode = new ObjectNode<>(object);
    (recursively ? recursiveObservedNodes : nonRecursiveObservedNodes).add(newNode);
  }
  
  public void addFactor(Factor f)
  {
    ObjectNode<Factor> factorNode = new ObjectNode<>(f);
    accessibilityGraph.add(factorNode);
    factors.add(factorNode);
  }
  
  public void addVariable(Object variable)
  {
    // TODO: discover names
    accessibilityGraph.add(variable);
  }
}

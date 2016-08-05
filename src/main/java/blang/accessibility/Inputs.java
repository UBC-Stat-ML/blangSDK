package blang.accessibility;

import java.util.LinkedHashSet;

import blang.accessibility.AccessibilityGraph.Node;
import blang.annotations.Samplers;
import blang.annotations.util.RecursiveAnnotationProducer;
import blang.annotations.util.TypeProvider;
import blang.core.Factor;
import blang.mcmc.Operator;

public class Inputs {
  public final AccessibilityGraph accessibilityGraph = new AccessibilityGraph();
  final LinkedHashSet<Node> 
    nonRecursiveObservedNodes = new LinkedHashSet<>(), 
    recursiveObservedNodes = new LinkedHashSet<>();
  
  final LinkedHashSet<ObjectNode<Factor>> factors = new LinkedHashSet<>();
  
  public final TypeProvider<Class<? extends Operator>> typeProvider = RecursiveAnnotationProducer.ofClasses(Samplers.class, true);
  
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

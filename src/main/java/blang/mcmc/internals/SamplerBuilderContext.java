package blang.mcmc.internals;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import blang.core.Factor;
import blang.inits.experiments.ExperimentResults;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.runtime.internals.objectgraph.Node;
import blang.runtime.internals.objectgraph.ObjectNode;
import blang.runtime.internals.objectgraph.StaticUtils;

public class SamplerBuilderContext 
{
  private GraphAnalysis graphAnalysis;
  private Node sampledVariable;
  private Set<Node> _sampledNodes = null;
  public final ExperimentResults monitoringStatistics; 
  
  SamplerBuilderContext(GraphAnalysis graphAnalysis, Node sampledVariable, ExperimentResults monitoringStatistics)
  {
    this.graphAnalysis = graphAnalysis;
    this.sampledVariable = sampledVariable;
    this.monitoringStatistics = monitoringStatistics;
  }
  
  private Set<Node> getSampledNodes()
  {
    if (_sampledNodes == null)
      _sampledNodes = graphAnalysis.accessibilityGraph
        .getAccessibleNodes(sampledVariable)
        .collect(Collectors.toSet());
    return _sampledNodes;
  }
  
  public Set<Node> sampledObjectsAccessibleFrom(Factor factor)
  {
    return graphAnalysis.accessibilityGraph
        .getAccessibleNodes(factor)
        .filter(n -> getSampledNodes().contains(n))
        .collect(Collectors.toSet());
  }
  
  public List<Factor> connectedFactors(Node node) 
  {
    List<Factor> result = new ArrayList<>();
    for (ObjectNode<Factor> n : graphAnalysis.getConnectedFactor(node))
      result.add(n.object);
    return result;
  }
  
  public boolean isLatent(Object object) 
  {
    return contain(graphAnalysis.getLatentVariables(), object);
  }
  
  public static boolean contain(Set<Node> nodes, Object object)
  {
    return nodes.contains(StaticUtils.node(object));
  }
  
  // Make sure the graph analysis does not get cloned later on
  // if that instance is saved somehow
  void tearDown()
  {
    this.graphAnalysis = null;
    this.sampledVariable = null;
  }
}

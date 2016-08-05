package runtime

import blang.core.Factor
import java.util.Set
import blang.core.ModelComponent
import java.util.ArrayList
import java.util.HashSet
import java.util.List
import blang.core.Model
import java.util.LinkedList
import briefj.run.Results
import blang.mcmc.SamplerBuilder
import runtime.objectgraph.GraphAnalysis
import blang.mcmc.Sampler
import java.lang.reflect.Field
import runtime.objectgraph.Inputs

class ModelUtils {
  
  /**
   * Find recursively all factors defined by the input ModelComponent.
   */
  def static List<Factor> factors(ModelComponent root) {
    var LinkedList<ModelComponent> queue = new LinkedList
    queue.add(root) 
    var List<Factor> result = new ArrayList 
    var Set<ModelComponent> visited = new HashSet
    while (!queue.isEmpty()) {
      var ModelComponent current = queue.poll() 
      visited.add(current) 
      if (current instanceof Factor) result.add(current as Factor) 
      if (current instanceof Model) {
        var Model model = current as Model 
        for (ModelComponent child : model.components()) 
          if (!visited.contains(child)) 
            queue.add(child) 
      }
    }
    return result 
  }
  
  def static List<Sampler> samplers(Model model) {
    var Inputs inputs = new Inputs() 
    for (Factor f : factors(model)) 
      inputs.addFactor((f as Factor)) 
    // register the variables
    for (Field f : model.getClass().getFields()) 
      if (!f.getType().isPrimitive()) 
        try {
          inputs.addVariable(f.get(model)) 
        } catch (Exception e) {
          throw new RuntimeException(e)
        }
    // analyze the object graph
    var GraphAnalysis graphAnalysis = GraphAnalysis.create(inputs) 
    // output visualization of the graph
    graphAnalysis.accessibilityGraph.exportDot(Results.getFileInResultFolder("accessibility-graph.dot")) 
    graphAnalysis.exportFactorGraphVisualization(Results.getFileInResultFolder("factor-graph.dot")) 
    System.out.println(graphAnalysis.toStringSummary()) 
    // create the samplers
    return SamplerBuilder.instantiateSamplers(graphAnalysis) 
  }
  
  // static utils only
  private new () {}  
}
package blang.mcmc

import java.util.List
import blang.core.LogScaleFactor
import blang.core.SupportFactor
import java.util.Random
import blang.examples.MarkovModel
import bayonet.marginal.DiscreteFactorGraph
import bayonet.graphs.GraphUtils
import blang.runtime.objectgraph.GraphAnalysis
import blang.runtime.objectgraph.ObjectNode
import java.util.LinkedHashSet
import blang.core.Factor
import briefj.BriefStrings
import briefj.BriefCollections

/**
 * Assumes there are no cycles in the observation links.
 * TODO: check it.
 */
class BaumWelch implements Sampler {
  
  @SampledVariable MarkovModel model
  
  @ConnectedFactor
  protected List<SupportFactor> supportFactors
  
  @ConnectedFactor
  protected List<LogScaleFactor> numericFactors
  
  // TODO: inject (perhaps another object?)
  GraphAnalysis graphAnalysis
  
  def private ObjectNode<?> latentObjectNode(int index) {
    return new ObjectNode(model.states.get(model.latent.index(i)))
  }

  override void execute(Random rand) {
    // TODO: cache these steps
    val int chainLen = model.time.indices.size
    val DiscreteFactorGraph<Integer> discreteFactorGraph = new DiscreteFactorGraph(GraphUtils.createChainTopology(chainLen))
    
    // find the observation factors
    for (var int i = 0; i < chainLen; i++) {
      val LinkedHashSet<ObjectNode<Factor>> factors = graphAnalysis.getConnectedFactor(latentObjectNode(i))
      // exclude left and right (assume to be the transitions)
      if (i > 0) {
        factors.removeAll(graphAnalysis.getConnectedFactor(latentObjectNode(i - 1)))
      }
      if (i < chainLen - 1) {
        factors.removeAll(graphAnalysis.getConnectedFactor(latentObjectNode(i + 1)))
      }
      
    }
    
  }
  
}
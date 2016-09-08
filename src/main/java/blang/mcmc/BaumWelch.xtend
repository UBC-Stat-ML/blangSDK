package blang.mcmc

import bayonet.distributions.Multinomial
import bayonet.graphs.GraphUtils
import bayonet.marginal.DiscreteFactorGraph
import bayonet.marginal.UnaryFactor
import bayonet.marginal.algo.ExactSampler
import bayonet.marginal.algo.SumProduct
import blang.core.Factor
import blang.core.LogScaleFactor
import blang.core.SupportFactor
import blang.examples.MarkovModel
import blang.runtime.objectgraph.GraphAnalysis
import blang.runtime.objectgraph.ObjectNode
import blang.types.IntVar
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.Random
import blang.inits.GlobalArg
import java.util.ArrayList
import xlinear.MatrixExtensions

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
  
  @GlobalArg 
  GraphAnalysis graphAnalysis
  
  def private ObjectNode<?> latentObjectNode(int index) {
    return new ObjectNode(model.chain.get(index))
  }
  
  override void execute(Random rand) {
    val int chainLen = model.chain.size()
    val int nStates = model.initialDistribution.nEntries
    val DiscreteFactorGraph<Integer> discreteFactorGraph = new DiscreteFactorGraph(GraphUtils.createChainTopology(chainLen))
    val double [][] transitions = MatrixExtensions::toArray(model.transitionProbabilities)
    // find the observation factors
    for (var int i = 0; i < chainLen; i++) {
      val LinkedHashSet<ObjectNode<Factor>> factors = unaryFactors(i)
      val currentVariable = getVar(i)
      val double [] unary = newDoubleArrayOfSize(nStates)
      for (var int s = 0; s < nStates; s++) {
        currentVariable.set(s)
        var double sum = 0.0
        for (ObjectNode<Factor> f : factors) {
          sum += (f.object as LogScaleFactor).logDensity()
        }
        unary.set(s, sum)
      }
      Multinomial.expNormalize(unary)
      val double [][] unaryMatrix = #[unary] 
      unaryMatrix.set(0, unary)
      discreteFactorGraph.setUnary(i, unaryMatrix)
      // set the transitions at same time b/w i and i+1
      if (i < chainLen - 1) {
        discreteFactorGraph.setBinary(i, i+1, transitions)
      }
    }
    // do the sampling!
    val innerSampler = discreteFactorGraph.getSampler()
    val SumProduct<Integer> sumProd = new SumProduct<Integer>(discreteFactorGraph)
    val ExactSampler<Integer> exactSampler = ExactSampler.posteriorSampler(sumProd, innerSampler)
    val Map<Integer, UnaryFactor<Integer>> sample = exactSampler.sample(rand, 0)
    for (var int i = 0; i < chainLen; i++) {
      val UnaryFactor<?> bitVector = sample.get(i)
      val double [][] current = DiscreteFactorGraph.getNormalizedCopy(bitVector);
      var int found = -1
      for (var int s = 0; s < nStates; s++) {
        if (current.get(0).get(s) > 0) {
          found = s
        }
      }
      getVar(i).set(found)
    }
  }
  
  def private getVar(int chainIndex) {
    return model.chain.get(chainIndex) as IntVar.IntScalar
  }
  
  override boolean setup() {
    // TODO: check structure is ok!
    computeUnaryCache()
    return true
  }
  
  var transient List<LinkedHashSet<ObjectNode<Factor>>> _unaryFactors_cache = null
  def private LinkedHashSet<ObjectNode<Factor>> unaryFactors(int i) {
    return _unaryFactors_cache.get(i)
  }
  
  def private void computeUnaryCache() {
    _unaryFactors_cache = new ArrayList
    val int chainLen = model.chain.size()
    for (var int i = 0; i < chainLen; i++) {
      val LinkedHashSet<ObjectNode<Factor>> factors = graphAnalysis.getConnectedFactor(latentObjectNode(i))
      // exclude left and right (assume to be the transitions)
      if (i > 0) {
        factors.removeAll(graphAnalysis.getConnectedFactor(latentObjectNode(i - 1)))
      }
      if (i < chainLen - 1) {
        factors.removeAll(graphAnalysis.getConnectedFactor(latentObjectNode(i + 1)))
      }
      _unaryFactors_cache.add(factors)
    }
  }
}
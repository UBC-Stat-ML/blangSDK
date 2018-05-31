package blang

import org.junit.Test
import blang.validation.internals.fixtures.Ising
import blang.validation.DiscreteMCTest
import blang.runtime.SampledModel
import blang.validation.internals.fixtures.IntNaiveMHSampler
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.mcmc.internals.SamplerBuilder
import blang.mcmc.internals.SamplerBuilderOptions
import java.util.List
import java.util.ArrayList

class TestDiscreteModels {
  
  
  @Test
  def void isingTests() {
    val n = 2
    val options = SamplerBuilderOptions::startWithOnly(IntNaiveMHSampler)
    val ising = new Ising.Builder().setN(n).build
    val graphAnalysis = new GraphAnalysis(ising)
    val kernels = SamplerBuilder.build(graphAnalysis, options)
    val model = new SampledModel(graphAnalysis, kernels)
    val rep = [isingState(it)]
    
    val test = new DiscreteMCTest(model, rep)
    test.checkStateSpaceSize((2 ** (n*n)) as int)
    test.checkInvariance
    test.checkIrreducibility
  }
  
  def static List<Integer> isingState(SampledModel m) {
    return new ArrayList((m.model as Ising).vertices.map[intValue].toList)
  }
}
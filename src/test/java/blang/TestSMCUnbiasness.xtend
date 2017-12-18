package blang

import org.junit.Test
import blang.validation.internals.fixtures.SmallHMM
import blang.engines.internals.schedules.FixedTemperatureSchedule
import bayonet.smc.ResamplingScheme
import blang.inits.experiments.Cores
import bayonet.distributions.ExhaustiveDebugRandom
import blang.runtime.internals.objectgraph.GraphAnalysis
import blang.mcmc.internals.SamplerBuilderOptions
import blang.mcmc.internals.SamplerBuilder
import blang.mcmc.internals.BuiltSamplers
import org.junit.Assert
import blang.runtime.SampledModel
import blang.engines.AdaptiveJarzynski
import java.util.function.Supplier
import java.util.List
import blang.core.IntVar
import blang.validation.internals.fixtures.ExactHMMCalculations
import blang.types.internals.IntScalar
import blang.runtime.Observations
import java.util.ArrayList
import blang.validation.internals.fixtures.IntNaiveMHSampler

class TestSMCUnbiasness {
  @Test def void testHMM() {
    
    SampledModel::check = true
    
    val int chainLen = 2
    
    val Observations observationsMarker = new Observations
    val List<Integer> observations = #[0, 1]
    val List<IntVar> observationsIntVar = new ArrayList(observations.map[new IntScalar(it)])
    observationsMarker.markAsObserved(observationsIntVar)
    
    val GraphAnalysis graphAnalysis = new GraphAnalysis(new SmallHMM.Builder().setObservations(observationsIntVar).build, observationsMarker)
    val SamplerBuilderOptions samplerOptions = SamplerBuilderOptions.startWithOnly(IntNaiveMHSampler)
    val BuiltSamplers kernels = SamplerBuilder.build(graphAnalysis, samplerOptions)
    Assert.assertEquals(chainLen, kernels.list.size)
    val SampledModel sampledModel = new SampledModel(graphAnalysis, kernels)
    
    
    val exhausiveRand = new ExhaustiveDebugRandom
    
    val AdaptiveJarzynski engine = new AdaptiveJarzynski() => [
      resamplingESSThreshold = 1.0 
      temperatureSchedule = new FixedTemperatureSchedule => [
        nTemperatures = 3
      ]
      resamplingScheme = ResamplingScheme.MULTINOMIAL
      nSamplesPerTemperature = 2
      nThreads = new Cores(1)
      random = exhausiveRand
    ]
    
    val expectedZEstimate = expectedZEstimate([engine.getApproximation(sampledModel).logNormEstimate], exhausiveRand)
    
    val ExactHMMCalculations exactCalc = new ExactHMMCalculations => [
      parameters = new ExactHMMCalculations.SimpleTwoStates()
      len = chainLen
    ]
    
    val trueZ = Math.exp(exactCalc.computeLogZ(observations))
    println("true normalization constant Z: " + trueZ)
    println("expected Z estimate over all traces: " + expectedZEstimate)
    
    Assert.assertEquals(trueZ, expectedZEstimate, 1e-10)
  }
  
  def static double expectedZEstimate(Supplier<Double> logZEstimator, ExhaustiveDebugRandom exhausiveRand) {
    var expectation = 0.0
    var nProgramTraces = 0
    var totalPr = 0.0
    while (exhausiveRand.hasNext) {
      val logZ = logZEstimator.get
      expectation += Math.exp(logZ) * exhausiveRand.lastProbability
      totalPr += exhausiveRand.lastProbability
      nProgramTraces++
    }
    println("nProgramTraces = " + nProgramTraces)
    return expectation
  }
  
}

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
import java.util.List
import blang.core.IntVar
import blang.validation.internals.fixtures.ExactHMMCalculations
import blang.types.internals.IntScalar
import blang.runtime.Observations
import java.util.ArrayList
import blang.validation.internals.fixtures.IntNaiveMHSampler
import blang.validation.UnbiasednessTest

class TestSMCUnbiasedness {
  @Test def void testHMM() {
    
    blang.System.out.silence
    
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
      nParticles = 2
      nThreads = Cores.single
      random = exhausiveRand
    ]
    
    val expectedZEstimate = UnbiasednessTest::expectedZEstimate([engine.getApproximation(sampledModel).logNormEstimate], exhausiveRand)
    
    val ExactHMMCalculations exactCalc = new ExactHMMCalculations => [
      parameters = new ExactHMMCalculations.SimpleTwoStates()
      len = chainLen
    ]
    
    val trueZ = Math.exp(exactCalc.computeLogZ(observations))
    println("true normalization constant Z: " + trueZ)
    println("expected Z estimate over all traces: " + expectedZEstimate)
    
    Assert.assertEquals(trueZ, expectedZEstimate, 1e-10)
  }
}

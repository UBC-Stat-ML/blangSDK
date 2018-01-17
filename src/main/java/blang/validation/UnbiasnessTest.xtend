package blang.validation

import java.util.function.Supplier
import bayonet.distributions.ExhaustiveDebugRandom

class UnbiasnessTest {
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
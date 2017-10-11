package blang.validation.internals.tests

import org.junit.Test
import blang.distributions.Normal
import blang.validation.ExactTest

import static blang.validation.internals.Helpers.realRealizationSquared
import static blang.validation.internals.Helpers.intRealizationSquared
import static blang.validation.internals.Helpers.simplexHash
import static blang.types.StaticUtils.realVar
import static blang.types.StaticUtils.intVar
import static blang.types.StaticUtils.simplex
import blang.distributions.Bernoulli
import blang.distributions.Beta
import blang.distributions.Binomial
import blang.distributions.Categorical
import blang.distributions.ContinuousUniform
import blang.distributions.Dirichlet

import static xlinear.MatrixOperations.denseCopy

class TestExactSDKDistributions {
  @Test def void test() {
    var ExactTest exact = new ExactTest => [
      
//      addTest(new Normal.Builder().setMean([0.2]).setVariance([0.1]).setRealization(realVar).build, realRealizationSquared)
//      addTest(new Bernoulli.Builder().setProbability([0.2]).setRealization(intVar).build,           intRealizationSquared)
//      addTest(new Beta.Builder().setAlpha([0.1]).setBeta([0.3]).setRealization(realVar).build,      realRealizationSquared)
//      addTest(new Binomial.Builder().setProbabilityOfSuccess([0.3]).setNumberOfTrials([3]).setNumberOfSuccesses(intVar).build,   intRealizationSquared)
//      addTest(new Categorical.Builder().setProbabilities(simplex(#[0.2, 0.3, 0.5])).setRealization(intVar).build,   intRealizationSquared)
//      addTest(new ContinuousUniform.Builder().setMin([-1.1]).setMax([-0.05]).setRealization(realVar).build,      realRealizationSquared)
      addTest(new Dirichlet.Builder().setConcentrations(denseCopy(#[0.2, 3.1])).setRealization(simplex(2)).build,      simplexHash)
      
    ]
    println("Corrected pValue = " + exact.correctedPValue)
    exact.check()
  }
}

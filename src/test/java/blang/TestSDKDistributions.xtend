package blang

import org.junit.Test
import blang.distributions.Normal
import blang.validation.ExactTest

import static blang.validation.internals.Helpers.realRealizationSquared
import static blang.validation.internals.Helpers.intRealizationSquared
import static blang.validation.internals.Helpers.listHash
import static blang.validation.internals.Helpers.vectorHash
import static blang.types.StaticUtils.realVar
import static blang.types.StaticUtils.intVar
import static blang.types.StaticUtils.simplex
import static blang.types.StaticUtils.transitionMatrix
import static blang.types.StaticUtils.listOfIntVars
import blang.distributions.Bernoulli
import blang.distributions.Beta
import blang.distributions.Binomial
import blang.distributions.Categorical
import blang.distributions.ContinuousUniform
import blang.distributions.Dirichlet

import static xlinear.MatrixOperations.denseCopy
import static xlinear.MatrixOperations.dense
import blang.distributions.Exponential
import blang.distributions.Gamma
import blang.distributions.MultivariateNormal
import xlinear.Matrix
import blang.distributions.Poisson
import blang.distributions.DiscreteUniform
import blang.distributions.MarkovChain
import blang.types.TransitionMatrix

class TestSDKDistributions { 

  @Test def void test() {
    var ExactTest exact = new ExactTest => [ 
      
      add(
        new Normal.Builder()
          .setMean([0.2])
          .setVariance([0.1])
          .setRealization(realVar).build, 
        realRealizationSquared
      )
      
      add(
        new Bernoulli.Builder()
          .setProbability([0.2])
          .setRealization(intVar).build, 
        intRealizationSquared
      )
      
      add(
        new Beta.Builder()
          .setAlpha([0.1])
          .setBeta([0.3])
          .setRealization(realVar).build, 
        realRealizationSquared
      )
      
      add(
        new Binomial.Builder()
          .setProbabilityOfSuccess([0.3])
          .setNumberOfTrials([3])
          .setNumberOfSuccesses(intVar).build, 
        intRealizationSquared
      )
      
      add(
        new Categorical.Builder()
          .setProbabilities(simplex(#[0.2, 0.3, 0.5]))
          .setRealization(intVar).build, 
        intRealizationSquared
      )
      
      add(
        new ContinuousUniform.Builder()
          .setMin([-1.1])
          .setMax([-0.05])
          .setRealization(realVar).build, 
        realRealizationSquared
      )
      
      add(
        new DiscreteUniform.Builder()
          .setMinInclusive([-1])
          .setMaxExclusive([5])
          .setRealization(intVar).build, 
        intRealizationSquared
      )
      
      add(
        new Dirichlet.Builder()
          .setConcentrations(denseCopy(#[0.2, 3.1, 5.0]))
          .setRealization(simplex(3)).build, 
        vectorHash
      ) 
      
      add(
        new Dirichlet.Builder()
          .setConcentrations(denseCopy(#[5.2, 3.1]))
          .setRealization(simplex(2)).build, 
        vectorHash
      ) 
      
      add(
        new Exponential.Builder()
          .setRate([2.3])
          .setRealization(realVar).build, 
        realRealizationSquared
      )
      
      add(
        new Gamma.Builder()
          .setRate([2.1])
          .setShape([0.9])
          .setRealization(realVar).build, 
        realRealizationSquared
      )
      
      add(
        new MultivariateNormal.Builder()
          .setMean(denseCopy(#[-3.1, 0.0, 1.2]))
          .setPrecision(precision.cholesky)
          .setRealization(dense(3)).build, 
        vectorHash
      )
      
      add(
        new Poisson.Builder()
          .setMean([3.4])
          .setRealization(intVar).build, 
        intRealizationSquared
      )
      
      add(
        new MarkovChain.Builder()
          .setInitialDistribution(simplex(#[0.3, 0.7]))
          .setTransitionProbabilities(transitionMatrix)
          .setChain(listOfIntVars(4)).build,  
        listHash
      )
      
    ]
    
    println("Corrected pValue = " + exact.correctedPValue)
    exact.check()
  }
  
  val Matrix precision = denseCopy(#[
    #[2.0, -1.3, 0.0],
    #[-1.3, 2.0, -0.8],
    #[0.0, -0.8, 2.1]
  ])
  
  val TransitionMatrix transitionMatrix = transitionMatrix(#[
    #[0.1, 0.9],
    #[0.6, 0.4]
  ])
}

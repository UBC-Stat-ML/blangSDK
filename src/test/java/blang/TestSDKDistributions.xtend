package blang

import org.junit.Test
import blang.distributions.Normal
import blang.validation.ExactInvarianceTest

import static blang.validation.internals.Helpers.realRealizationSquared
import static blang.validation.internals.Helpers.intRealizationSquared
import static blang.validation.internals.Helpers.listHash
import static blang.validation.internals.Helpers.vectorHash
import static blang.types.StaticUtils.realVar
import static blang.types.StaticUtils.intVar
import static blang.types.StaticUtils.listOfIntVars
import static blang.types.StaticUtils.listOfRealVars

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
import blang.examples.DynamicNormalMixture
import blang.validation.internals.fixtures.ListHash
import blang.validation.internals.fixtures.VectorHash
import blang.examples.rockets.SimpleHierarchicalModel
import blang.types.Plate
import blang.types.internals.ColumnName
import blang.io.GlobalDataSource
import blang.types.Plated
import blang.types.DenseTransitionMatrix
import static blang.types.StaticUtils.denseSimplex
import static blang.types.StaticUtils.denseTransitionMatrix
import blang.types.StaticUtils
import blang.validation.internals.fixtures.GLM
import blang.examples.MixtureModel

class TestSDKDistributions { 
  
  @Test 
  def void test() {
    test(new ExactInvarianceTest)
  }
  
  def static void setup(ExactInvarianceTest test) {
    test => [ 
      
      // Test SDK distributions individually
      
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
          .setProbabilities(denseSimplex(#[0.2, 0.3, 0.5]))
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
          .setRealization(denseSimplex(3)).build, 
        vectorHash
      ) 
      
      add(
        new Dirichlet.Builder()
          .setConcentrations(denseCopy(#[5.2, 3.1]))
          .setRealization(denseSimplex(2)).build, 
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
      
      // Test several distributions simultaneously in the context of 
      // prototypical complex models.
      
      add(
        new MarkovChain.Builder()
          .setInitialDistribution(denseSimplex(#[0.3, 0.7]))
          .setTransitionProbabilities(transitionMatrix)
          .setChain(listOfIntVars(4)).build,  
        listHash
      )
      
      add(
        new DynamicNormalMixture.Builder()
          .setObservations(listOfRealVars(4))
          .setNLatentStates(2).build,  
        [ListHash.hash(states)], 
        [VectorHash.hash(initialDistribution)],
        [VectorHash.hash(transitionProbabilities.row(0))]
      )
      
      add(
        new SimpleHierarchicalModel.Builder()
          .setRocketTypes(Plate::simpleStringPlate(new ColumnName("rocketType"), 2))
          .setNumberOfLaunches(Plated::latent(new ColumnName("nLaunches"), [intVar]))
          .setFailureProbabilities(Plated::latent(new ColumnName("failPrs"), [realVar]))
          .setNumberOfFailures(Plated::latent(new ColumnName("failPrs"), [intVar]))
          .setData(GlobalDataSource::empty).build,
        [p0.doubleValue]
      )
      
      add(
        new GLM.Builder()
          .setOutput(listOfIntVars(3))
          .setDesignMatrix(designMatrix).build,
        [coefficients.get(0).realPart.doubleValue],
        [coefficients.get(0).isZero.intValue as double]
      )
      
      add(
        new MixtureModel.Builder()
          .setObservations(listOfRealVars(2)).build,
        [observations.get(0).doubleValue] 
      )
      
    ]
  }

  def static void test(ExactInvarianceTest test) {
    setup(test)
    println("Corrected pValue = " + test.correctedPValue)
    test.check()
  }
  
  val static Matrix precision = denseCopy(#[
    #[2.0, -1.3, 0.0],
    #[-1.3, 2.0, -0.8],
    #[0.0, -0.8, 2.1]
  ])
  
  val static DenseTransitionMatrix transitionMatrix = StaticUtils.denseTransitionMatrix(#[
    #[0.1, 0.9],
    #[0.6, 0.4]
  ])
  
  val static Matrix designMatrix = denseCopy(#[ // n = 3, p = 2
    #[2.0, -1.3],
    #[-1.3, 2.0],
    #[0.0, -0.8]
  ])
}

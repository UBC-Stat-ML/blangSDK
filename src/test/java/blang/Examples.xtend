package blang

import blang.core.Model
import blang.distributions.Bernoulli
import blang.distributions.Beta
import blang.distributions.Binomial
import blang.distributions.Categorical
import blang.distributions.ContinuousUniform
import blang.distributions.Dirichlet
import blang.distributions.DiscreteUniform
import blang.distributions.Exponential
import blang.distributions.Gamma
import blang.distributions.MultivariateNormal
import blang.distributions.Normal
import blang.distributions.Poisson
import blang.examples.DynamicNormalMixture
import blang.examples.MixtureModel
import blang.validation.internals.fixtures.SimpleHierarchicalModel
import blang.io.GlobalDataSource
import blang.types.DenseTransitionMatrix
import blang.types.Plate
import blang.types.Plated
import blang.types.StaticUtils
import blang.types.internals.ColumnName
import blang.validation.Instance
import blang.validation.internals.fixtures.ListHash
import blang.validation.internals.fixtures.MarkovChain
import blang.validation.internals.fixtures.SpikedGLM
import blang.validation.internals.fixtures.VectorHash
import java.util.ArrayList
import java.util.List
import java.util.function.Function
import xlinear.Matrix

import static blang.types.StaticUtils.constant
import static blang.types.StaticUtils.denseSimplex
import static blang.types.StaticUtils.intVar
import static blang.types.StaticUtils.listOfIntVars
import static blang.types.StaticUtils.listOfRealVars
import static blang.types.StaticUtils.realVar
import static blang.validation.internals.Helpers.intRealizationSquared
import static blang.validation.internals.Helpers.listHash
import static blang.validation.internals.Helpers.realRealizationSquared
import static blang.validation.internals.Helpers.vectorHash
import static xlinear.MatrixOperations.dense
import static xlinear.MatrixOperations.denseCopy
import blang.validation.internals.fixtures.Multimodal
import blang.validation.internals.fixtures.RealRealizationSquared
import blang.distributions.internals.Helpers

class Examples {
  
  public val List<Instance<? extends Model>> all = new ArrayList
  
  public val normal = add(
    new Normal.Builder()
      .setMean(constant(0.2))
      .setVariance(constant(0.1))
      .setRealization(realVar).build, 
    realRealizationSquared
  )
      
  public val bern = add(
    new Bernoulli.Builder()
      .setProbability(constant(0.2))
      .setRealization(intVar).build, 
    intRealizationSquared
  )
      
  public val beta = add(
    new Beta.Builder()
      .setAlpha(constant(1.0))
      .setBeta(constant(3.0))
      .setRealization(realVar).build, 
    realRealizationSquared
  )
  
  public val sparseBeta = add(
    new Beta.Builder()
      .setAlpha(constant(Helpers::concentrationWarningThreshold))
      .setBeta(constant(Helpers::concentrationWarningThreshold))
      .setRealization(realVar).build, 
    realRealizationSquared
  )
      
  public val binom = add(
    new Binomial.Builder()
      .setProbabilityOfSuccess(constant(0.3))
      .setNumberOfTrials(constant(3))
      .setNumberOfSuccesses(intVar).build, 
    intRealizationSquared 
  )
  
  public val cat = add(
    new Categorical.Builder()
      .setProbabilities(denseSimplex(#[0.2, 0.3, 0.5]))
      .setRealization(intVar).build, 
    intRealizationSquared
  )
  
  public val contunif = add(
    new ContinuousUniform.Builder()
      .setMin(constant(-1.1))
      .setMax(constant(-0.05))
      .setRealization(realVar).build, 
    realRealizationSquared
  )
  
  public val discrunif = add(
    new DiscreteUniform.Builder()
      .setMinInclusive(constant(-1))
      .setMaxExclusive(constant(5))
      .setRealization(intVar).build, 
    intRealizationSquared
  )
  
  public val dirichlet = add(
    new Dirichlet.Builder()
      .setConcentrations(denseCopy(#[Helpers::concentrationWarningThreshold, 3.1, 5.0]))
      .setRealization(denseSimplex(3)).build, 
    vectorHash
  ) 
  
  public val dirichlet2 = add(
    new Dirichlet.Builder()
      .setConcentrations(denseCopy(#[5.2, 3.1]))
      .setRealization(denseSimplex(2)).build, 
    vectorHash
  ) 
  
  public val exp = add(
    new Exponential.Builder()
      .setRate(constant(2.3))
      .setRealization(realVar).build, 
    realRealizationSquared
  )
  
  public val gamma = add(
    new Gamma.Builder()
      .setRate(constant(2.1))
      .setShape(constant(0.9))
      .setRealization(realVar).build, 
    realRealizationSquared
  )
  
  public val mvn = add(
    new MultivariateNormal.Builder()
      .setMean(denseCopy(#[-3.1, 0.0, 1.2]))
      .setPrecision(precision.cholesky)
      .setRealization(dense(3)).build,  
    vectorHash
  )
  
  public val poi = add(
    new Poisson.Builder()
      .setMean(constant(3.4))
      .setRealization(intVar).build, 
    intRealizationSquared
  )
  
  // Test several distributions simultaneously in the context of 
  // prototypical complex models.
  
  public val mc = add(
    new MarkovChain.Builder()
      .setInitialDistribution(denseSimplex(#[0.3, 0.7]))
      .setTransitionProbabilities(transitionMatrix)
      .setChain(listOfIntVars(4)).build,  
    listHash
  )
  
  public val dnm = add(
    new DynamicNormalMixture.Builder()
      .setObservations(listOfRealVars(4))
      .setNLatentStates(2).build,  
    [ListHash.hash(states)], 
    [VectorHash.hash(initialDistribution)],
    [VectorHash.hash(transitionProbabilities.row(0))]
  )
  
  public val shm = add(
    new SimpleHierarchicalModel.Builder()
      .setRocketTypes(Plate::simpleStringPlate(new ColumnName("rocketType"), 2))
      .setNumberOfLaunches(Plated::latent(new ColumnName("nLaunches"), [intVar]))
      .setFailureProbabilities(Plated::latent(new ColumnName("failPrs"), [realVar]))
      .setNumberOfFailures(Plated::latent(new ColumnName("failPrs"), [intVar]))
      .setData(GlobalDataSource::empty).build,
    [a.doubleValue]
  )
  
  public val sglm = add(
    new SpikedGLM.Builder()
      .setOutput(listOfIntVars(3))
      .setDesignMatrix(designMatrix).build,
    [coefficients.get(0).realPart.doubleValue],
    [coefficients.get(0).isZero.intValue as double]
  )
  
  public val mix = add(
    new MixtureModel.Builder()
      .setObservations(listOfRealVars(2)).build,
    [observations.get(0).doubleValue] 
  )
  
  public val multimodal = add(
    new Multimodal.Builder().build,
    new RealRealizationSquared()
  )
  
  public static Matrix precision = denseCopy(#[
    #[2.0, -1.3, 0.0],
    #[-1.3, 2.0, -0.8],
    #[0.0, -0.8, 2.1]
  ])
  
  public static DenseTransitionMatrix transitionMatrix = StaticUtils.denseTransitionMatrix(#[
    #[0.1, 0.9],
    #[0.6, 0.4]
  ])
  
  public static Matrix designMatrix = denseCopy(#[ // n = 3, p = 2
    #[2.0, -1.3],
    #[-1.3, 2.0],
    #[0.0, -0.8]
  ])
  
  def <M extends Model> Instance<M> add(
    M model, 
    @SuppressWarnings("unchecked") Function<M, Double> ... testFunctions) {
    val Instance<M> result = new Instance<M>(model, testFunctions)
    all.add(result)
    return result
  }
}

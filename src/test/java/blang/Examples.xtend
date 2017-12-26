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

import static blang.validation.internals.Helpers.intRealizationSquared
import static blang.validation.internals.Helpers.listHash
import static blang.validation.internals.Helpers.realRealizationSquared
import static blang.validation.internals.Helpers.vectorHash
import static xlinear.MatrixOperations.dense
import static xlinear.MatrixOperations.denseCopy
import blang.validation.internals.fixtures.Multimodal
import blang.validation.internals.fixtures.RealRealizationSquared
import blang.distributions.internals.Helpers
import blang.distributions.NegativeBinomial
import blang.distributions.NegativeBinomial_MeanParam
import blang.distributions.NormalField
import blang.types.Precision.Diagonal
import blang.validation.internals.fixtures.PoissonNormalField
import blang.distributions.SymmetricDirichlet
import blang.distributions.SimplexUniform
import static blang.types.StaticUtils.latentInt
import static blang.types.StaticUtils.latentReal
import static blang.types.StaticUtils.constantInt
import static blang.types.StaticUtils.constantReal
import static blang.types.StaticUtils.latentListOfInt
import static blang.types.StaticUtils.latentListOfReal
import static blang.types.StaticUtils.latentSimplex
import static blang.types.StaticUtils.constantSimplex
import xlinear.DenseMatrix

class Examples {
  
  public val List<Instance<? extends Model>> all = new ArrayList
  
  public val normal = add(
    new Normal.Builder()
      .setMean(constantReal(0.2))
      .setVariance(constantReal(0.1))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
      
  public val bern = add(
    new Bernoulli.Builder()
      .setProbability(constantReal(0.2))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
      
  public val beta = add(
    new Beta.Builder()
      .setAlpha(constantReal(1.0))
      .setBeta(constantReal(3.0))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val negBinomial = add( 
    new NegativeBinomial.Builder()
      .setK(latentInt)
      .setP(constantReal(0.1))
      .setR(constantReal(2.1))
        .build,
    intRealizationSquared
  )
  
  public val negBinomial_mv = add( 
    new NegativeBinomial_MeanParam.Builder()
      .setK(latentInt)
      .setMean(constantReal(1.1))
      .setOverdispersion(constantReal(0.3))
        .build,
    intRealizationSquared
  )
  
  public val sparseBeta = add(
    new Beta.Builder()
      .setAlpha(constantReal(Helpers::concentrationWarningThreshold))
      .setBeta(constantReal(Helpers::concentrationWarningThreshold))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
      
  public val binom = add(
    new Binomial.Builder()
      .setProbabilityOfSuccess(constantReal(0.3))
      .setNumberOfTrials(constantInt(3))
      .setNumberOfSuccesses(latentInt)
        .build, 
    intRealizationSquared 
  )
  
  public val cat = add(
    new Categorical.Builder()
      .setProbabilities(constantSimplex(0.2, 0.3, 0.5))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  public val contunif = add(
    new ContinuousUniform.Builder()
      .setMin(constantReal(-1.1))
      .setMax(constantReal(-0.05))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val discrunif = add(
    new DiscreteUniform.Builder()
      .setMinInclusive(constantInt(-1))
      .setMaxExclusive(constantInt(5))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  public val dirichlet = add(
    new Dirichlet.Builder()
      .setConcentrations(denseCopy(#[Helpers::concentrationWarningThreshold, 3.1, 5.0]).readOnlyView)
      .setRealization(latentSimplex(3))
        .build, 
    vectorHash
  ) 
  
  public val dirichlet2 = add(
    new Dirichlet.Builder()
      .setConcentrations(denseCopy(#[5.2, 3.1]).readOnlyView)
      .setRealization(latentSimplex(2))
        .build, 
    vectorHash
  ) 
  
  public val dirichletSymm = add(
    new SymmetricDirichlet.Builder()
      .setConcentration(constantReal(4.4))
      .setDim(3)
      .setRealization(latentSimplex(3))
        .build, 
    vectorHash
  ) 
  
  public val simplexUni = add(
    new SimplexUniform.Builder()
      .setDim(3)
      .setRealization(latentSimplex(3))
        .build, 
    vectorHash
  ) 
  
  public val exp = add(
    new Exponential.Builder()
      .setRate(constantReal(2.3))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val gamma = add(
    new Gamma.Builder()
      .setRate(constantReal(2.1))
      .setShape(constantReal(0.9))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val mvn = add(
    new MultivariateNormal.Builder()
      .setMean(denseCopy(#[-3.1, 0.0, 1.2]).readOnlyView)
      .setPrecision(precision.cholesky)
      .setRealization(dense(3))
        .build,  
    vectorHash
  )
  
  public val poi = add(
    new Poisson.Builder()
      .setMean(constantReal(3.4))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  // Test several distributions simultaneously in the context of 
  // prototypical complex models.
  
  public val mc = add(
    new MarkovChain.Builder()
      .setInitialDistribution(constantSimplex(0.3, 0.7))
      .setTransitionProbabilities(transitionMatrix)
      .setChain(latentListOfInt(4))
        .build,  
    listHash
  )
  
  public val dnm = add(
    new DynamicNormalMixture.Builder()
      .setObservations(latentListOfReal(4))
      .setNLatentStates(2)
        .build,  
    [ListHash.hash(states)], 
    [VectorHash.hash(initialDistribution)],
    [VectorHash.hash(transitionProbabilities.row(0))]
  )
  
  public val shm = add(
    new SimpleHierarchicalModel.Builder()
      .setRocketTypes(Plate::simpleStringPlate(new ColumnName("rocketType"), 2))
      .setNumberOfLaunches(Plated::latent(new ColumnName("nLaunches"), [latentInt]))
      .setFailureProbabilities(Plated::latent(new ColumnName("failPrs"), [latentReal]))
      .setNumberOfFailures(Plated::latent(new ColumnName("failPrs"), [latentInt]))
      .setData(GlobalDataSource::empty)
        .build,
    [a.doubleValue]
  )
  
  public val sglm = add(
    new SpikedGLM.Builder()
      .setOutput(latentListOfInt(3))
      .setDesignMatrix(designMatrix)
        .build,
    [coefficients.get(0).realPart.doubleValue],
    [coefficients.get(0).isZero.intValue as double]
  )
  
  public val mix = add(
    new MixtureModel.Builder()
      .setObservations(latentListOfReal(2))
        .build,
    [observations.get(0).doubleValue] 
  )
  
  public val multimodal = add(
    new Multimodal.Builder()
      .build,
    new RealRealizationSquared()
  )
  
  val col = new ColumnName("plate")
  val plate = Plate::simpleIntegerPlate(col, 2)
  public val normalField = add(
    new NormalField.Builder()
      .setRealization(Plated::latent(col, [latentReal]))
      .setPrecision(new Diagonal(constantReal(1.4), plate))
        .build,
    [getRealization().get(plate.indices.iterator.next).doubleValue ** 2]
  )
  
  public val poissonNormal = add(
    new PoissonNormalField.Builder()
      .setPlate(plate)
      .setLatents(Plated::latent(col, [latentReal]))
      .setObservations(Plated::latent(col, [latentInt]))
        .build,
    [getLatents().get(plate.indices.iterator.next).doubleValue ** 2]
  )
  
  public static DenseMatrix precision = denseCopy(#[
    #[2.0, -1.3,  0.0],
    #[-1.3, 2.0, -0.8],
    #[0.0, -0.8,  2.1]
  ])
  
  public static DenseTransitionMatrix transitionMatrix = StaticUtils.constantTransitionMatrix(#[
    #[0.1, 0.9],
    #[0.6, 0.4]
  ])
  
  public static Matrix designMatrix = denseCopy(#[ // n = 3, p = 2
    #[ 2.0, -1.3],
    #[-1.3,  2.0],
    #[ 0.0, -0.8]
  ])
  
  def <M extends Model> Instance<M> add(
    M model, 
    @SuppressWarnings("unchecked") Function<M, Double> ... testFunctions) {
    val Instance<M> result = new Instance<M>(model, testFunctions)
    all.add(result)
    return result
  }
}

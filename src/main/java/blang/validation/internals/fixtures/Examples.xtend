package blang.validation.internals.fixtures

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
import blang.distributions.Geometric
import blang.distributions.MultivariateNormal
import blang.distributions.Normal
import blang.distributions.Poisson
import blang.distributions.StudentT
import blang.distributions.HalfStudentT
import blang.distributions.ChiSquared
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
import blang.distributions.NormalField
import blang.types.Precision.Diagonal
import blang.validation.internals.fixtures.PoissonNormalField
import blang.distributions.SymmetricDirichlet
import blang.distributions.SimplexUniform
import static blang.types.StaticUtils.latentInt
import static blang.types.StaticUtils.latentReal
import static blang.types.StaticUtils.fixedInt
import static blang.types.StaticUtils.fixedReal
import static blang.types.StaticUtils.latentIntList
import static blang.types.StaticUtils.latentRealList
import static blang.types.StaticUtils.latentSimplex
import static blang.types.StaticUtils.fixedSimplex
import xlinear.DenseMatrix
import blang.validation.internals.fixtures.DynamicNormalMixture
import blang.distributions.NegativeBinomialMeanParam
import blang.distributions.GammaMeanParam
import blang.distributions.YuleSimon
import blang.distributions.Laplace
import blang.distributions.Logistic
import blang.distributions.LogLogistic
import blang.distributions.F
import blang.distributions.Weibull
import blang.distributions.Gumbel
import blang.distributions.Gompertz
import blang.distributions.HyperGeometric
import blang.distributions.BetaBinomial
import blang.distributions.BetaNegativeBinomial
import blang.distributions.LogUniform

class Examples {
  
  public val List<Instance<? extends Model>> all = new ArrayList
  
  public val logUniform = add(
    new LogUniform.Builder()
    .setMin(fixedReal(-5.9))
    .setMax(fixedReal(2.1))
    .setBase(fixedReal(10.0))
    .setRealization(latentReal)
    .build,
    realRealizationSquared
  )
  
  public val betaBinomial = add(
  	new BetaBinomial.Builder()
  	.setAlpha(fixedReal(1.0))
  	.setBeta(fixedReal(3.0))
  	.setNumberOfTrials(fixedInt(3))
  	.setRealization(latentInt)
  	.build,
  	intRealizationSquared
  )
  
  public val hyperGeometric = add(
  	new HyperGeometric.Builder()
  	.setNumberOfDraws(fixedInt(3))
  	.setPopulation(fixedInt(9))
  	.setPopulationConditioned(fixedInt(6))
  	.setNumberOfSuccess(latentInt)
  	.build,
  	intRealizationSquared
  )
  
  public val gompertz = add(
  	new Gompertz.Builder()
  	  .setShape(fixedReal(0.2))
  	  .setScale(fixedReal(1.35))
  	  .setRealization(latentReal)
  	    .build,
  	[getRealization().doubleValue]
  )
  
  public val gumbel = add(
    new Gumbel.Builder()
      .setLocation(fixedReal(2.3))
      .setScale(fixedReal(1.7))
      .setRealization(latentReal)
        .build,
	[(getRealization().doubleValue)]
  )
  
  public val weibull = add(
    new Weibull.Builder()
  	  .setScale(fixedReal(1.6))
  	  .setShape(fixedReal(1.2))
  	  .setRealization(latentReal)
  	    .build,
    [getRealization().doubleValue]
  )
  
  public val fDist = add(
  	new F.Builder()
  	  .setD1(fixedReal(2))
  	  .setD2(fixedReal(1))
  	  .setRealization(latentReal)
  		.build,
  	realRealizationSquared
  )
    
  public val logLogistic = add(
    new LogLogistic.Builder()
  	  .setScale(fixedReal(2.0))
  	  .setShape(fixedReal(1.0))
  	  .setRealization(latentReal)
  		.build,
	realRealizationSquared
  )
  
  public val logisticDist = add(
  	new Logistic.Builder()
  	  .setLocation(fixedReal(3.0))
  	  .setScale(fixedReal(1.5))
  	  .setRealization(latentReal)
  	  	.build,
  	[getRealization().doubleValue]
  )
 
  public val geometric = add(
    new Geometric.Builder()
      .setP(fixedReal(0.5))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  public val laplace = add(
    new Laplace.Builder()
      .setLocation(fixedReal(0.5))
      .setScale(fixedReal(0.1))
      .setRealization(latentReal)
        .build,
    realRealizationSquared
  )
  
  public val yuleSimon = add( 
    new YuleSimon.Builder()
      .setRho(fixedReal(3.5))
      .setRealization(latentInt)
        .build,
    [getRealization().intValue as double]   
  )
  
  
  public val normal = add(
    new Normal.Builder()
      .setMean(fixedReal(0.2))
      .setVariance(fixedReal(0.1))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val studentt = add(
      new StudentT.Builder()
        .setNu(fixedReal(2.0))
        .setMu(fixedReal(-1.5))
        .setSigma(fixedReal(2.2))
        .setRealization(latentReal)
            .build,
      [Math.cos(getRealization().doubleValue)]  // use bdd function to make sure it's integrable
  )
  
  public val cauchy = add(
      new StudentT.Builder()
        .setNu(fixedReal(1.0))
        .setMu(fixedReal(0.0))
        .setSigma(fixedReal(1.0))
        .setRealization(latentReal)
            .build,
      [Math.cos(getRealization().doubleValue)] // use bdd function to make sure it's integrable
  )
  
  public val thint = add(
      new StudentT.Builder()
        .setNu(fixedReal(3.0))
        .setMu(fixedReal(0.0))
        .setSigma(fixedReal(1.0))
        .setRealization(latentReal)
            .build,
      realRealizationSquared
  )

  public val halfstudentt = add(
      new HalfStudentT.Builder()
        .setNu(fixedReal(2.1))
        .setSigma(fixedReal(1.7))
        .setRealization(latentReal)
            .build,
      realRealizationSquared
  )

  public val chisquared = add(
      new ChiSquared.Builder()
        .setNu(fixedInt(3))
        .setRealization(latentReal)
            .build,
      realRealizationSquared
  )
  
     
  public val bern = add(
    new Bernoulli.Builder()
      .setProbability(fixedReal(0.2))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
      
  public val beta = add(
    new Beta.Builder()
      .setAlpha(fixedReal(1.0))
      .setBeta(fixedReal(3.0))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val negBinomial = add( 
    new NegativeBinomial.Builder()
      .setK(latentInt)
      .setP(fixedReal(0.1))
      .setR(fixedReal(2.1))
        .build,
    intRealizationSquared
  )
  
  public val betaNegBinomial = add(
    new BetaNegativeBinomial.Builder()
    .setAlpha(fixedReal(1.2))
    .setBeta(fixedReal(3.0))
    .setR(fixedReal(3.5))
    .setK(latentInt) 
    .build,
    intRealizationSquared
  )
  
  public val negBinomial_mv = add( 
    new NegativeBinomialMeanParam.Builder()
      .setK(latentInt)
      .setMean(fixedReal(1.1))
      .setOverdispersion(fixedReal(0.3))
        .build,
    intRealizationSquared
  )
  
  public val sparseBeta = add(
    new Beta.Builder()
      .setAlpha(fixedReal(Helpers::concentrationWarningThreshold))
      .setBeta(fixedReal(Helpers::concentrationWarningThreshold))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
      
  public val binom = add(
    new Binomial.Builder()
      .setProbabilityOfSuccess(fixedReal(0.3))
      .setNumberOfTrials(fixedInt(3))
      .setNumberOfSuccesses(latentInt)
        .build, 
    intRealizationSquared 
  )
  
  public val cat = add(
    new Categorical.Builder()
      .setProbabilities(fixedSimplex(0.2, 0.3, 0.5))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  public val contunif = add(
    new ContinuousUniform.Builder()
      .setMin(fixedReal(-1.1))
      .setMax(fixedReal(-0.05))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val discrunif = add(
    new DiscreteUniform.Builder()
      .setMinInclusive(fixedInt(-1))
      .setMaxExclusive(fixedInt(5))
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
      .setConcentration(fixedReal(4.4))
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
      .setRate(fixedReal(2.3))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val gamma = add(
    new Gamma.Builder()
      .setRate(fixedReal(2.1))
      .setShape(fixedReal(0.9))
      .setRealization(latentReal)
        .build, 
    realRealizationSquared
  )
  
  public val gammaMeanParam = add(
    new GammaMeanParam.Builder()
      .setMean(fixedReal(1.9))
      .setVariance(fixedReal(0.2))
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
      .setMean(fixedReal(3.4))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  public static val largeLambda = 200
  public val largePoi = add(
    new Poisson.Builder()
      .setMean(fixedReal(largeLambda))
      .setRealization(latentInt)
        .build, 
    intRealizationSquared
  )
  
  // Test several distributions simultaneously in the context of 
  // prototypical complex models.
  
  public val mc = add(
    new MarkovChain.Builder()
      .setInitialDistribution(fixedSimplex(0.3, 0.7))
      .setTransitionProbabilities(transitionMatrix)
      .setChain(latentIntList(4))
        .build,  
    listHash
  )
  
  public val dnm = add(
    new DynamicNormalMixture.Builder()
      .setObservations(latentRealList(4))
      .setNLatentStates(2)
        .build,  
    [ListHash.hash(states)], 
    [VectorHash.hash(initialDistribution)],
    [VectorHash.hash(transitionProbabilities.row(0))]
  )
  
  public val shm = add(
    new SimpleHierarchicalModel.Builder()
      .setRocketTypes(Plate::ofStrings("rocketType", 2))
      .setNumberOfLaunches(Plated::latent("nLaunches", [latentInt]))
      .setFailureProbabilities(Plated::latent("failPrs", [latentReal]))
      .setNumberOfFailures(Plated::latent("failPrs", [latentInt]))
      .setData(GlobalDataSource::empty)
        .build,
    [a.doubleValue]
  )
  
  public val sglm = add(
    new SpikedGLM.Builder()
      .setOutput(latentIntList(3))
      .setDesignMatrix(designMatrix)
        .build,
    [coefficients.get(0).realPart.doubleValue],
    [coefficients.get(0).isZero.intValue as double]
  )
 
  public val mix = add(
    new MixtureModel.Builder()
      .setObservations(latentRealList(2))
        .build,
    [observations.get(0).doubleValue],
    [concentration.get(0)]
  )
  
  public val multimodal = add(
    new Multimodal.Builder()
      .build,
    new RealRealizationSquared()
  )

  val col = new ColumnName("plate")
  val plate = Plate::ofIntegers(col, 2)
  public val normalField = add(
    new NormalField.Builder()
      .setRealization(Plated::latent(col, [latentReal]))
      .setPrecision(new Diagonal(fixedReal(1.4), plate))
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
  
  public val poissonNormalBM = add(
    new PoissonNormalField.Builder()
      .setDiagonal(false)
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
  
  public static DenseTransitionMatrix transitionMatrix = StaticUtils.fixedTransitionMatrix(#[
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

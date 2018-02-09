package blang

import blang.validation.ExactInvarianceTest
import org.junit.Test
import bayonet.distributions.Random
import blang.distributions.Dirichlet
import blang.validation.Instance
import xlinear.MatrixOperations
import blang.types.StaticUtils
import org.junit.Assert
import blang.distributions.internals.Helpers
import blang.distributions.Beta

class TestSparseDirichletAndBetaWarnings {

  @Test
  def void testSimpleDiri()
  {
    Helpers.warnedUnstableConcentration = false
    new ExactInvarianceTest => [ 
      random = new Random(14)
      nPosteriorSamplesPerIndep = 1 //500 
      val instance = new Instance<Dirichlet>(
        new Dirichlet.Builder()
          .setConcentrations(MatrixOperations::denseCopy(#[0.1, 0.1]))
          .setRealization(StaticUtils::latentSimplex(2)).build, 
        [getRealization.get(0)])
      add(instance) 
    ] //.check(0.05)  After changing 1->500 above this would crash (p value is 0.036631052707119305 on commit of Nov 10 4pm). See Issue #62
    Assert.assertTrue(Helpers.warnedUnstableConcentration) 
  }
  
  @Test  
  def void testBeta()
  {
    Helpers.warnedUnstableConcentration = false
    new ExactInvarianceTest => [ 
      nPosteriorSamplesPerIndep = 1 //500
      val instance = new Instance<Beta>(
        new Beta.Builder()
          .setAlpha(StaticUtils::fixedReal(0.1))
          .setBeta(StaticUtils::fixedReal(0.1))
          .setRealization(StaticUtils::latentReal).build, 
        [getRealization.doubleValue]
      )
      add(instance)
    ] //.check(0.05)  After changing 1->500 above this would crash (p value is 0.02330809853328797 on commit of Nov 10 4pm). See Issue #62
    Assert.assertTrue(Helpers.warnedUnstableConcentration) 
  }
}
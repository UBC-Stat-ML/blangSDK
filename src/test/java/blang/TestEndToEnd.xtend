package blang

import blang.runtime.Runner
import org.junit.Assert
import org.junit.Test
import blang.validation.internals.fixtures.Doomsday
import blang.runtime.SampledModel
import blang.validation.internals.fixtures.NoGen
import blang.validation.internals.fixtures.Diffusion
import blang.validation.internals.fixtures.SometimesNaN
import blang.validation.internals.fixtures.BadPlate
import blang.validation.internals.fixtures.DynamicNormalMixture
import blang.validation.internals.fixtures.FixedMatrix
import blang.validation.internals.fixtures.HierarchicalModel
import blang.examples.MixtureModel
import blang.validation.internals.fixtures.Ising
import blang.validation.internals.fixtures.PCR
import blang.distributions.PoissonAllInOne
import blang.validation.internals.fixtures.PoissonNormalField
import blang.engines.internals.ladders.Polynomial
import blang.engines.internals.ladders.Geometric
import blang.engines.internals.ladders.EquallySpaced

class TestEndToEnd {
  
  @Test
  def void doomsday() {
    
    SampledModel::check = true
    
    for (engine : #["SCM", "PT"]) {
      Assert.assertEquals(
        0, 
        Runner::start(
          "--model", Doomsday.canonicalName,
          "--model.rate", "1.0",
          "--model.z", "NA",
          "--model.y", "1.2",
          "--engine", engine
        )
      )
    }
  }
  
  @Test
  def void diffusion() {
    
    SampledModel::check = true
    
    Assert.assertEquals(
      0, 
      Runner::start(
        "--model", Diffusion.canonicalName
      )
    )
    
  }
  
  @Test
  def void stripped() {
    
    SampledModel::check = true
    
    Assert.assertEquals(
      0, 
      Runner::start(
        "--model", NoGen.canonicalName,
        "--checkIsDAG", "false",
        "--engine.usePriorSamples", "false",
        "--stripped", "true",
        "--engine", "PT",
        "--engine.nChains", "1"
      )
    )
  }
  
  @Test
  def void nanNotOK() {
    SampledModel::check = true
    Assert.assertNotEquals(
      0, 
      Runner::start(
        "--model", SometimesNaN.canonicalName
      )
    )
  }
  
  @Test
  def void nanOK() {
    SampledModel::check = true
    Assert.assertEquals(
      0, 
      Runner::start(
        "--model", SometimesNaN.canonicalName,
        "--treatNaNAsNegativeInfinity", "true"
      )
    )
  }
  
  @Test
  def void badPlate() {
    SampledModel::check = true
    Assert.assertNotEquals(
      0, 
      Runner::start(
        "--model", BadPlate.canonicalName
      )
    )
  }
  
  @Test
  def void morePT_Tests() {
    val models = #[
      Diffusion, 
      FixedMatrix, 
      Ising
    ]
    val nThreads = #[1,2]
    val ladders = #[Geometric, EquallySpaced, Polynomial]
    val nChains = #[1, 2, 4]
    val usePriors = #[true, false]
    val rev = #[true, false]
    for (model : models) {
      println("Testing PT for " + model.name)
      for (lad : ladders.map[name])
      for (useP : usePriors.map[toString])
      for (nc : nChains.map[toString])
      for (rv : rev.map[toString])
      for (nt : nThreads.map[toString]) {
        Assert.assertEquals(
        0, 
        Runner::start(
          "--model", model.canonicalName,
          "--engine.nChains", nc,
          "--engine.reversible", rv,
          "--engine.usePriorSamples", useP,
          "--engine.ladder", lad,
          "--engine.nThreads", "fixed",
          "--engine.nThreads.number", nt,
          "--engine", "PT",
          "--engine.nScans", "10",
          "--engine.nPassesPerScan", "1"
          )
        )
      }
    }
  }
}

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
}

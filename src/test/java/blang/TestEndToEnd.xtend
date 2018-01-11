package blang

import blang.runtime.Runner
import org.junit.Assert
import org.junit.Test
import blang.validation.internals.fixtures.Doomsday
import blang.runtime.SampledModel
import blang.validation.internals.fixtures.NoGen

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
  def void stripped() {
    
    // --checkIsDAG false --engine PT --engine.usePriorSamples false --skipForwardSamplerConstruction true --engine.ladder.nChains 1
    Assert.assertEquals(
      0, 
      Runner::start(
        "--model", NoGen.canonicalName,
        "--checkIsDAG", "false",
        "--engine.usePriorSamples", "false",
        "--skipForwardSamplerConstruction", "true",
        "--engine", "PT",
        "--engine.ladder.nChains", "1"
      )
    )
    
  }
  
}

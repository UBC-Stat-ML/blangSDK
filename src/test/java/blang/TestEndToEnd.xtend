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
import blang.validation.internals.fixtures.FixedMatrix
import blang.validation.internals.fixtures.Ising
import blang.engines.internals.ladders.Polynomial
import blang.engines.internals.ladders.Geometric
import blang.engines.internals.ladders.EquallySpaced
import blang.engines.internals.factories.PT.InitType
import blang.validation.internals.fixtures.Unid
import blang.validation.internals.fixtures.CustomAnnealRef
import briefj.BriefIO
import java.io.File
import blang.validation.internals.fixtures.CustomAnnealTest
import java.nio.file.Files
import blang.engines.internals.factories.PT
import java.util.ArrayList
import blang.inits.experiments.tabwriters.TidySerializer
import blang.inits.experiments.tabwriters.factories.CSV
import blang.validation.internals.fixtures.NotNormalForm

class TestEndToEnd {
  
  @Test
  def void doomsday() {
    
    SampledModel::check = true
    
    for (engine : #["SCM", "PT", "AIS"]) {
      Assert.assertEquals(
        0, 
        Runner::start(
          "--model", Doomsday.canonicalName,
          "--experimentConfigs.maxIndentationToPrint", "-1",
          "--model.rate", "1.0",
          "--model.z", "NA",
          "--model.y", "1.2",
          "--engine", engine
        )
      )
    }
  }
  
  @Test
  def void notNormalForm() {
    
    SampledModel::check = true
    
    Assert.assertEquals(
      0, 
      Runner::start(
        "--model", NotNormalForm.canonicalName,
        "--experimentConfigs.maxIndentationToPrint", "-1",
        "--engine", "MCMC"
      )
    )
  }
  
  @Test
  def void diffusion() {
    
    SampledModel::check = true
    
    Assert.assertEquals(
      0, 
      Runner::start(
        "--model", Diffusion.canonicalName,
        "--experimentConfigs.maxIndentationToPrint", "-1"
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
        "--experimentConfigs.maxIndentationToPrint", "-1",
        "--checkIsDAG", "false",
        "--engine.usePriorSamples", "false",
        "--stripped", "true",
        "--engine", "PT",
        "--engine.initialization", "COPIES",
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
        "--model", SometimesNaN.canonicalName,
        "--experimentConfigs.maxIndentationToPrint", "-1"
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
        "--experimentConfigs.maxIndentationToPrint", "-1",
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
        "--model", BadPlate.canonicalName,
        "--experimentConfigs.maxIndentationToPrint", "-1"
      )
    )
  }
  
  @Test
  def void testNormalizationEstimates() {
    val engines = {#[
      #["--engine.logNormalizationEstimator", "steppingStone",            " --engine.nScans", "2_000"],
      #["--engine.logNormalizationEstimator", "thermodynamicIntegration", " --engine.nScans", "2_000"],
      #["--engine", "SCM",                                            " --engine.nParticles", "2_000"]
    ]}
    val estimates = newArrayOfSize(engines.size)
    var int i = 0;
    for (engine : engines) {
      val exec = Files.createTempDirectory("r" + (i+1)).toFile
      val args = new ArrayList(#["--model", Ising.canonicalName, "--experimentConfigs.maxIndentationToPrint", "-1"])
      args.addAll(engine)
      val runner = Runner::create(
        exec,
        args
      )
      runner.run
      val logNormFile = CSV::csvFile(exec, Runner.LOG_NORMALIZATION_ESTIMATE)
      val estimateStr = BriefIO::readLines(logNormFile).indexCSV.last.get.get(TidySerializer::VALUE)
      val estimate = Double.parseDouble(estimateStr)
      estimates.set(i, estimate)
      i++
    }

    for (int j : 1 ..< estimates.size) {
      Assert.assertEquals(estimates.get(j-1), estimates.get(j), 0.1)    
    }
  }
  
  @Test
  def void testCustomAnnealer() {
    val r1 = Runner::create(
      Files.createTempDirectory("r1").toFile,
      "--model", CustomAnnealRef.canonicalName
    )
    r1.run();
    val l1 = (r1.engine as PT).targetState.logDensity
    
    val r2 = Runner::create(
      Files.createTempDirectory("r2").toFile,
      "--model", CustomAnnealTest.canonicalName
    )
    r2.run()
    val l2 = (r2.engine as PT).targetState.logDensity
    
    Assert.assertEquals(l1, l2, 1e-10)
  }
  
  @Test
  def void morePT_Tests() {
    val models = #[
      Diffusion, 
      FixedMatrix, 
      Ising,
      Unid
    ]
    val nThreads = #[1,2]
    val ladders = #[Geometric, EquallySpaced, Polynomial]
    val inits = #[InitType.COPIES, InitType.FORWARD, InitType.SCM]
    val nChains = #[1, 2, 4]
    val usePriors = #[true, false]
    val rev = #[true, false]
    for (model : models) {
      println("Testing PT for " + model.name)
      for (init : inits.map[toString])
      for (lad : ladders.map[name])
      for (useP : usePriors.map[toString])
      for (nc : nChains.map[toString])
      for (rv : rev.map[toString])
      for (nt : nThreads.map[toString]) {
        Assert.assertEquals(
        0, 
        Runner::start(
          "--model", model.canonicalName,
          "--experimentConfigs.maxIndentationToPrint", "-1",
          "--engine.initialization", init,
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

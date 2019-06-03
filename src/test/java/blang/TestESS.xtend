package blang

import java.io.File
import bayonet.distributions.Random
import blang.runtime.Runner
import blang.inits.experiments.tabwriters.TidySerializer
import briefj.BriefIO
import org.junit.Test
import blang.runtime.internals.ComputeESS

import static org.apache.commons.lang3.RandomStringUtils.randomAlphabetic
import blang.runtime.internals.ComputeESS.AR
import blang.runtime.internals.ComputeESS.ACT
import org.junit.Assert
import blang.runtime.internals.ComputeESS.Batch
import java.util.Optional

class TestESS {
  
  def File ar1(Random rand, int number, double a0, double a1, double sd0, double sd1) {
    val tempFile = File.createTempFile("ar1", "" + randomAlphabetic(10)) 
    tempFile.deleteOnExit
    var x = 0.0
    var y = 2.1
    val contents = new StringBuilder
    contents.append("index," + Runner::sampleColumn + "," + TidySerializer::VALUE + "\n")
    for (i : 0 ..< number) {
      x = a0 * x + sd0 * rand.nextGaussian
      y = a1 * y + sd1 * rand.nextGaussian
      contents.append("0," + i + "," + x + "\n")
      contents.append("1," + i + "," + y + "\n")
    }
    BriefIO::write(tempFile, contents.toString)
    return tempFile
  }
  
  def File referenceFile(double statioSD0, double statioSD1) {
    val tempFile = File.createTempFile("ar1-ref", "" + randomAlphabetic(10)) 
    val b = new Batch
    tempFile.deleteOnExit
    val contents = new StringBuilder
    contents.append("index," + b.referenceMeanColumn + "," + b.referenceSDColumn + "\n")
    contents.append("0," + 0.0 + "," + statioSD0 + "\n")
    contents.append("1," + 0.0 + "," + statioSD1 + "\n")
    BriefIO::write(tempFile, contents.toString)
    return tempFile
  }
  
  @Test
  def testAnalyticEss() {
    val rand = new Random(1)
    val a0 = 0.2
    val a1 = 0.4
    val sd0 = 1.2
    val sd1 = 0.1
    val essName = "temp-ess.csv"
    val result = new File(essName)
    result.deleteOnExit
    val n = 100000
    val samples = ar1(rand, n, a0, a1, sd0, sd1)
    val batchWithRef = new Batch => [
      referenceFile = Optional.of(referenceFile(
        Math::sqrt(statioVariance(sd0, a0)), 
        Math::sqrt(statioVariance(sd1, a1))
      ))
    ]
    for (curEstimator : #[new AR, new ACT, new Batch, batchWithRef]) {
      val essComputer = new ComputeESS => [
        estimator = curEstimator
        inputFile = samples
        experimentConfigs.managedExecutionFolder = false
        experimentConfigs.recordExecutionInfo = false
        burnInFraction = 0.0
        output = essName
      ]
      essComputer.computeEss
      essComputer.results.flushAll
      for (line : BriefIO::readLines(result).indexCSV) {
        val a =  if (line.get("index") == "0") a0 else a1
        val sd = if (line.get("index") == "0") sd0 else sd1
        // known stationary dist (Normal) of an AR(1), see e.g. wikipedia article
        val variance = statioVariance(sd, a)
        // known form for AR(1), see e.g.: https://ocw.mit.edu/courses/economics/14-384-time-series-analysis-fall-2013/lecture-notes/MIT14_384F13_lec2.pdf, p.3
        val asymptoticVariance = sd * sd / (1.0 - a) / (1.0 - a) 
        val theoreticalESS = variance * n / asymptoticVariance
        val estimatedESS = Double.parseDouble(line.get("value"))
        val relError = Math::abs(theoreticalESS - estimatedESS) / theoreticalESS
        println("Relative error for " + curEstimator.class.simpleName + ": " + relError)
        Assert.assertTrue("Checking rel error to be less than 10%: " + relError, relError < 0.1)
      }
    }
  }
  
  def static statioVariance(double noiseSD, double a) {
    noiseSD * noiseSD / (1.0 - a * a) 
  }
}
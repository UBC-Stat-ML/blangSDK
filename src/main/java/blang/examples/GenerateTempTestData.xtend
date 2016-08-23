package blang.examples

import briefj.run.Mains
import java.util.List
import briefj.BriefIO
import briefj.run.Results
import java.io.PrintWriter
import java.util.Random
import bayonet.rplot.PlotHistogram
import java.util.ArrayList
import java.io.File
import blang.runtime.Runner
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import blang.types.NA

class GenerateTempTestData implements Runnable {
  
  int nData = 1000
  double p = 0.2
  List<Double> means = #[-2.0, 5.0]
  double dataGenNoise = 0.1 // std dev
  
  def static void main(String [] args) {
    Mains.instrumentedRun(args, new GenerateTempTestData)
  }
  
  override void run() {
    val File data = generateData()
    val File analysis = runBlang(data)
    // model.logVariances.mixture=0
    
    for (var int i = 0; i < 2; i++) {
      val _i = i
      val SummaryStatistics stat = new SummaryStatistics
      BriefIO.readLines(analysis)
        .indexCSV()
        .filter[get("variable") == "model.means.mixture=" + _i]
        .map[Double.parseDouble(get("value"))]
        .forEach[stat.addValue(it)]
      println(stat.mean)
    }
  }
  
  def File runBlang(File dataFile) {
    val File latents = createDummyLatentFile()
    Runner.main(
      "--model", "MixtureModel", 
      "--model.sample", "sample", 
      "--model.mixture", "mixture",
      "--model.hyperMean", "0",
      "--model.logHyperVar", "3",
      "--model.logPi", "NA",
      "--model.means", latents.absolutePath,
      "--model.logVariances", latents.absolutePath,
      "--model.clusterIndicators", dataFile.absolutePath,
      "--model.observations", dataFile.absolutePath,
      "--mcmc.nIterations", "10000",
      "--mcmc.thinningPeriod", "100"
      )
    return Results.getFileInResultFolder(Runner.SAMPLE_FILE)
  }
  
  def File createDummyLatentFile() {
    val File result = Results.getFileInResultFolder("latents.csv")
    val PrintWriter out = BriefIO.output(result)
    out.println("mixture,means,logVariances")
    for (var int mixIdx = 0; mixIdx < 2; mixIdx++) {
      out.println('''«mixIdx»,«NA::SYMBOL»,«NA::SYMBOL»''')
    }
    out.close()
    return result
  }
  
  def File generateData() {
    val Random rand = new Random(1)
    val List<Double> data = new ArrayList
    val File result = Results.getFileInResultFolder("data.csv")
    val PrintWriter out = BriefIO.output(result)
    out.println("sample,clusterIndicators,observations")
    for (var int dataIdx = 0; dataIdx < nData; dataIdx++) {
      val int idx = if (rand.nextDouble < p) 1 else 0
      val double mean = means.get(idx)
      val double datum = rand.nextGaussian * dataGenNoise + mean
      data.add(datum)
      out.println('''«dataIdx»,«NA::SYMBOL»,«datum»''')
    }
    out.close
    PlotHistogram.from(data).toPDF(Results.getFileInResultFolder("data.pdf"))
    return result
  }
  
}
package blang.engines.internals.ptanalysis

import java.util.List
import java.io.File
import briefj.BriefIO
import java.util.ArrayList
import blang.inits.ConstructorArg
import blang.inits.Input
import blang.inits.DesignatedConstructor
import blang.inits.DefaultValue
import org.apache.commons.math3.stat.descriptive.SummaryStatistics

class Paths {
  val List<List<Integer>> paths
  
  /**
   * The list of temperature indices visited by the particle started 
   * at the given input chain index.
   * 
   * Index 0 is room temperature chain.
   */
  def List<Integer> get(int chainIndexAtBeginning) {
    return paths.get(chainIndexAtBeginning)
  }
  
  def int nRejuvenations() {
    var count = 0
    for (chain : 0 ..< nChains)
      count += nRejuvenations(chain)
    return count
  }
  
  def SummaryStatistics cycleTimeStatistics() {
    val result = new SummaryStatistics
    for (chain : 0 ..< nChains)
      cycleTimeStatistics(chain, result)
    return result
  }
  
  private def int nRejuvenations(int chainIndexAtBeginning) {
    var newSample = false
    var count = 0
    for (state : get(chainIndexAtBeginning)) 
      if (state == 0 && newSample) {
        newSample = false
        count++
      } else if (state == nChains - 1) 
        newSample = true
    return count
  }
  
  private def void cycleTimeStatistics(int chainIndexAtBeginning, SummaryStatistics stats) {
    val priorIdx = nChains - 1
    val postIdx = 0
    var mode = -1
    var cycleSize = 0
    for (state : get(chainIndexAtBeginning)) {
      switch mode {
        case -1 : { // before getting to prior chain for first time
          if (state == priorIdx) 
            mode = 0
        }
        case 0 : { // part of a cycle between prior and post
          cycleSize++
          if (state == postIdx)
            mode = 1
        }
        case 1 : { // part of a cycle between post and prior
          cycleSize++
          if (state == priorIdx) {
            mode = 0
            stats.addValue(cycleSize)
            cycleSize = 0
          }
        }
      }
    }
  }
  
  def int nChains() { return paths.size }
  def int nIterations() { return paths.get(0).size }
  
  @DesignatedConstructor
  new(
    @Input(formatDescription = "Path to csv file swapIndicators") String swapIndicatorPath, 
    @ConstructorArg("startIteration") @DefaultValue("0") int startIteration, 
    @ConstructorArg("endIteration")   @DefaultValue("INF") int endIteration 
  ) {
    val swapIndicators = new File(swapIndicatorPath)
    val nChains = nChains(swapIndicators)
    val List<List<Integer>> paths = initPaths(nChains)
    var justSwapped = false
    for (line : BriefIO.readLines(swapIndicators).indexCSV) {
      val int sample = Integer.parseInt(line.get("sample"))
      if (sample >= startIteration && sample < endIteration) {
        val int chain = Integer.parseInt(line.get("chain"))
        val int indic = Integer.parseInt(line.get("value"))
        if (justSwapped) {
          justSwapped = false
        } else {
          val p0 = paths.get(chain)
          if (indic == 1) {
            if (justSwapped) throw new RuntimeException
            val p1 = paths.get(chain + 1) 
            paths.set(chain, p1)
            paths.set(chain + 1, p0)
            p1.add(chain)
            p0.add(chain + 1)
            justSwapped = true
          } else {
            p0.add(chain)
          }
        } 
      }
    }
    this.paths = sortPaths(paths)
  }
  
  private def static List<List<Integer>> sortPaths(List<List<Integer>> paths) {
    val result = new ArrayList<List<Integer>>
    val len = paths.get(0).size
    for (i : 0 ..< paths.size) 
      result.add(null)
    for (path : paths) {
      if (path.size != len) throw new RuntimeException
      result.set(path.get(0), path)
    }
    return result
  }
  
  private def static List<List<Integer>> initPaths(int nChains) {
    val result = new ArrayList<List<Integer>>
    for (c : 0 ..< nChains) {
      val path = new ArrayList<Integer>
      path.add(c)
      result.add(path)
    }
    return result
  }
  
  private def static nChains(File swapIndicators) {
    var max = Integer.MIN_VALUE
    for (line : BriefIO.readLines(swapIndicators).indexCSV) {
      val int chain = Integer.parseInt(line.get("chain"))
      val int sample = Integer.parseInt(line.get("sample"))
      max = Math.max(max, chain)
      if (sample > 0)
        return max + 1
    }
    return max + 1
  }
}
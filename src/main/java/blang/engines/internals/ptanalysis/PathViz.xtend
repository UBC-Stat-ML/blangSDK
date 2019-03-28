package blang.engines.internals.ptanalysis

import viz.core.Viz
import viz.core.PublicSize
import viz.core.Viz.PrivateSize
import blang.inits.ConstructorArg
import blang.inits.experiments.Experiment
import blang.inits.DesignatedConstructor
import blang.inits.DefaultValue
import blang.inits.Arg
import java.util.Optional

class PathViz extends Viz {
  val Paths paths
  
  @Arg Optional<Integer> boldTrajectory
  
                         @DefaultValue("true")
  @Arg boolean useAcceptRejectColours = true
  
  float ratio = 0.5f
  
  @DesignatedConstructor
  new(
    @ConstructorArg("swapIndicators") Paths paths, 
    @ConstructorArg("size") @DefaultValue("height", "300") PublicSize publicSize
  ) {
    super(publicSize)
    this.paths = paths
  }
  
  val baseWeight = 0.05f
  override protected draw() {
    translate(0.5f, 0.5f)
    val boldStroke = 6 * baseWeight
    val minY = 0f
    val maxY = paths.nChains - 1
    val minX = 0f
    val maxX = ratio * (paths.nIterations - 1)
    for (c : 0 ..< paths.nChains) {
      if (boldTrajectory.orElse(-1) == c)
        strokeWeight(boldStroke)
      else
        strokeWeight(baseWeight)
      if (!useAcceptRejectColours)
        setColour(c)
      val path = paths.get(c)
      for (i : 1 ..< paths.nIterations) {
        if (useAcceptRejectColours)
          setColour(path.get(i-1) != path.get(i))
        val y0 = path.get(i-1)
        val y1 =path.get(i)
        line(ratio*(i-1), y0, ratio*i, y1)
        if (useAcceptRejectColours)
          stroke(0, 0, 0)
        ellipse(ratio*(i - 1), y0, 0.1f, 0.1f)
      }
      ellipse(maxX, path.get(paths.nIterations - 1), 0.1f, 0.1f)
    }
    // black boundaries (masks corner case red/green color off there)
    stroke(0, 0, 0)
    strokeWeight(boldStroke)
    line(minX, minY, maxX, minY) 
    line(minX, maxY, maxX, maxY) 
  }
  
  def void setColour(boolean accepted) {
    if (accepted) stroke(0, 204, 0)
    else stroke(204, 0, 0)
  }
  
  def void setColour(int chainIndex) {
    val from = color(204, 102, 0)
    val to = color(0, 102, 153)
    val interpolated = lerpColor(from, to, 1.0f * chainIndex / paths.nChains)
    stroke(interpolated)
  }
  
  override protected privateSize() { new PrivateSize(paths.nIterations * ratio, paths.nChains) }
  
  static def void main(String [] args) { Experiment::start(args) }
}
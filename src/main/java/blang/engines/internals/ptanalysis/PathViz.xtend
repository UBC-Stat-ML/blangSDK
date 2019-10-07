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
import processing.core.PApplet

class PathViz extends Viz {
  public val Paths paths
  
  @Arg public Optional<Integer> boldTrajectory = Optional.empty
  
                         @DefaultValue("true")
  @Arg public boolean useAcceptRejectColours = true
  
  public float ratio = 0.5f
  
  val boolean animate
  val int maxDisplayed = 100
  public var int current = 1 
  
  @DesignatedConstructor
  new(
    @ConstructorArg("swapIndicators") Paths paths, 
    @ConstructorArg("size") @DefaultValue("height", "300") PublicSize publicSize,
    @ConstructorArg("animate") @DefaultValue("false") boolean animate
  ) {
    super(publicSize)
    this.paths = paths
    this.animate = animate
  }
  
  val baseWeight = 0.1f
  override protected draw() {
    translate(0.5f, 0.5f)
    val boldStroke = 6 * baseWeight
    val minY = 0f
    val maxY = paths.nChains - 1
    val minX = 0f
    val maxX = ratio * (paths.nIterations - 1)
    strokeWeight(0f)
    rect(0, 0, paths.nIterations * ratio, paths.nChains - 1f)
    for (c : 0 ..< paths.nChains) {
      if (boldTrajectory.orElse(-1) == c)
        strokeWeight(boldStroke)
      else
        strokeWeight(baseWeight)
      val path = paths.get(c)
      var float alpha = 255f
      for (i : iterationIndices) {
        if (useAcceptRejectColours)
          setColour(path.get(i-1) != path.get(i), alpha)
        else 
          setColour(c, alpha)
        if (animate)
          alpha -= 255f / maxDisplayed
        val y0 = path.get(i-1)
        val y1 = path.get(i)
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
    if (animate)
      current = (println(current) + 1) % paths.nIterations
  }
  
  def Iterable<Integer> iterationIndices() {
    if (animate) return (current .. Math.max(1, current - maxDisplayed))
    else return (1 ..< paths.nIterations)
  }
  
  def void setColour(boolean accepted, float alpha) {
    if (accepted) stroke(0, 204, 0, alpha)
    else stroke(204, 0, 0, alpha)
  }
  
  def void setColour(int chainIndex, float alpha) {
    stroke(colour(chainIndex), alpha)
  }
  
  def int colour(int chainIndex) {
    val from = -3381760 //color(204, 102, 0)
    val to = -16750951 //color(0, 102, 153)
    return PApplet::lerpColor(from, to, 1.0f * chainIndex / paths.nChains, PApplet.RGB)
  }

  
  override protected privateSize() { new PrivateSize(paths.nIterations * ratio, paths.nChains) }
  
  static def void main(String [] args) { Experiment::start(args) }
}
package blang.runtime.internals

import viz.core.Viz
import viz.core.PublicSize
import viz.core.Viz.PrivateSize
import java.util.List
import java.util.ArrayList
import briefj.BriefIO
import java.io.File
import blang.engines.internals.ptanalysis.PathViz
import blang.engines.internals.ptanalysis.Paths
import gifAnimation.GifMaker

class CompositeSampling2dViz extends Viz {
  
  val Sampling2dViz viz1
  val Sampling2dViz viz2
  val PathViz pViz
  
  var GifMaker gif = null
  var boolean setup = false
  
  new(PublicSize publicSize, Sampling2dViz viz1, Sampling2dViz viz2, PathViz pViz) {
    super(publicSize)
    this.viz1 = viz1
    this.viz2 = viz2
    this.pViz = pViz
  }
  
  override protected draw() {
    if (!setup) {
      this.gif = new GifMaker(applet, "export.gif") 
      setup = true
    }
    
    background(51);
    addChild(viz1,0,1)
    addChild(viz2,1,1)
    
    val numberVariables = 2
    val nIterationFitting = numberVariables * pViz.paths.nChains * 2 // assume ration = 0.5
    
    pushMatrix
    translate(-(pViz.current / nIterationFitting) * 2, 0)
    addChild(pViz,0,0)
    popMatrix
    if (gif !== null) {
      gif.setDelay(1);
      gif.addFrame();
    }
    if (pViz.current == pViz.paths.nIterations - 2) {
      if (gif !== null) {
        gif.finish
        gif = null
      }
      pViz.current = 1
      viz1.current = 0
      viz2.current = 0
    }
  }
  
  
  override protected privateSize() {
    new PrivateSize(2, 2)
  }
  
  def static List<Integer> colours(PathViz viz) {
    val ArrayList<Integer> result = new ArrayList((0 .. viz.paths.nIterations).map[null].toList)
    for (startIndex : 0 ..< viz.paths.nChains) {
      val path = viz.paths.get(startIndex)
      for (i : 0 ..< viz.paths.nIterations) {
        if (path.get(i) == 0)
          result.set(i, viz.colour(startIndex))
      }
    }
    return result
  }
  
  def static Sampling2dViz viz(String name1, String name2, List<Integer> colours) {
    val xsf = new File("/Users/bouchard/w/blangDemos/results/all/2019-10-02-22-46-26-nbXPrSyN.exec/samples/" + name1 + ".csv")
    val ysf = new File("/Users/bouchard/w/blangDemos/results/all/2019-10-02-22-46-26-nbXPrSyN.exec/samples/" + name2 + ".csv")
    
    val xs = BriefIO::readLines(xsf).indexCSV.map[Double.parseDouble(get("value"))].toList
    val ys = BriefIO::readLines(ysf).indexCSV.map[Double.parseDouble(get("value"))].toList
    
    return new Sampling2dViz(fixWidth(1), xs, ys, colours)
  }
  
  def static void main(String [] args) {
    
    val paths = new Paths(("/Users/bouchard/w/blangDemos/results/all/2019-10-02-22-46-26-nbXPrSyN.exec/monitoring/swapIndicators.csv"), 0, 1000)
    val pathViz = new PathViz(paths, fixHeight(1), true)
    pathViz.useAcceptRejectColours = false
   
    val colours = colours(pathViz)
    val viz1 = viz("beta", "km0", colours)
    val viz2 = viz("beta", "delta", colours)
    
    new CompositeSampling2dViz(fixHeight(900), viz1, viz2, pathViz).show
  }
}
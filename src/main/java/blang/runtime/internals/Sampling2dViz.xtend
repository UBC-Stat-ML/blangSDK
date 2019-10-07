package blang.runtime.internals

import viz.core.Viz
import viz.core.PublicSize
import viz.core.Viz.PrivateSize
import java.util.List
import briefj.BriefIO
import java.io.File

class Sampling2dViz extends Viz {
  
  val int maxDisplayed = 100
  
  val List<Double> xs
  val List<Double> ys
  
  val double minX
  val double minY
  val double maxX
  val double maxY
  
  val List<Integer> rgbs
  public var int current = 0
  
  new(PublicSize publicSize, List<Double> xs, List<Double> ys, List<Integer> rgbs) {
    super(publicSize)
    this.xs = xs
    this.ys = ys
    this.rgbs = rgbs
    this.minX = xs.min
    this.minY = ys.min
    this.maxX = xs.max
    this.maxY = ys.max
  }
  
  override protected draw() {
    strokeWeight(0.005f)
    //background(51);
    
    // Draw a line connecting the points
    var float alpha = 255f
    for(var int i = current; i > Math.max(0, current - maxDisplayed); i--) {    
      stroke(rgbs.get(i), alpha) 
      alpha -= 255f / maxDisplayed
      line(get(i-1,true), get(i-1,false), get(i,true), get(i,false));
    }
    current = (current + 1) % xs.size
  }
  
  def float get(int index, boolean isX) {
    val double raw = (if (isX) xs else ys).get(index)
    val double min = (if (isX) minX else minY)
    val double max = (if (isX) maxX else maxY)
    val normalized = (((raw - min) / (max - min)) as float) 
    if (isX) return normalized
    else return 1.0f - normalized
  }
  
  override protected privateSize() {
    new PrivateSize(1, 1)
  }
  
  def static void main(String [] args) {
    val xsf = new File("/Users/bouchard/w/blangDemos/results/all/2019-10-02-22-46-26-nbXPrSyN.exec/samples/beta.csv")
    val ysf = new File("/Users/bouchard/w/blangDemos/results/all/2019-10-02-22-46-26-nbXPrSyN.exec/samples/km0.csv")
    
    val xs = BriefIO::readLines(xsf).indexCSV.map[Double.parseDouble(get("value"))].toList
    val ys = BriefIO::readLines(ysf).indexCSV.map[Double.parseDouble(get("value"))].toList
    
    
    val rgbs = (0 .. xs.size).map[255].toList
    new Sampling2dViz(fixWidth(640), xs, ys, rgbs).show
  }
}
package blang.examples.sdes

import java.util.List
import blang.inits.ConstructorArg
import java.util.ArrayList
import java.util.Collections
import java.util.HashSet
import blang.inits.DesignatedConstructor
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.LinkedHashSet

class Mesh {
  
  val List<Double> referencePoints
  
  @Accessors(PUBLIC_GETTER)
  val double epsilon
  
  val List<Double> allPoints
  
  @DesignatedConstructor
  new (
    @ConstructorArg("referencePoints") List<Double> referencePoints, 
    @ConstructorArg("epsilon")         double epsilon
  ) {
    // copy and remove duplicates
    this.referencePoints = new ArrayList(new HashSet(referencePoints))
    this.epsilon = epsilon
    Collections.sort(this.referencePoints)
    val LinkedHashSet<Double> setAllPoints = new LinkedHashSet
    var double t = referencePoints.get(0)
    setAllPoints.add(t)
    var int curRefIdx = 0
    while (curRefIdx + 1 < referencePoints.size) {
      t = t + epsilon
      if (t > referencePoints.get(curRefIdx + 1)) {
        setAllPoints.add(referencePoints.get(curRefIdx + 1))
        curRefIdx++
      } else if (curRefIdx + 1 < referencePoints.size) {
        setAllPoints.add(t)
      }
    }
    // above code could create duplicates if e.g. observations fall 
    this.allPoints = new ArrayList(setAllPoints)
    println(allPoints)
  }
  
  def int totalNumberOfPoints() {
    return allPoints.size
  }
  
  def double time(int index) {
    return allPoints.get(index)
  }
}
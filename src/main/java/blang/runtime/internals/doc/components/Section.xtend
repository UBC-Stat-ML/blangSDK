package blang.runtime.internals.doc.components

import java.util.ArrayList
import java.util.List

import static blang.runtime.internals.doc.html.Tags.*
import blang.runtime.internals.doc.html.Tag
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

class Section {
  
  public String name
  private int depth = 1
  
  public val List in = new ArrayList
  
  def void subsection(Procedure1<Section> init) {
    val Section result = new Section => init
    result.depth++
    in += result
  }
  
  override toString() {
    val myIn = in
    val result = div [
      cla = "row marketing"
      if (name !== null) {
        in.add(title)
      }
      in.addAll(myIn)
    ]
    return result.toString
  }
  
  def title() {
    val Tag t = switch (depth) {
      case 1 : h1[]
      case 2 : h2[]
      case 3 : h3[]
      default : throw new RuntimeException
    }
    t.in += name
    return t
  }
  
}
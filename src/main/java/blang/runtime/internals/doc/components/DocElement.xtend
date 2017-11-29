package blang.runtime.internals.doc.components

import java.util.List
import java.util.ArrayList
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.eclipse.xtend.lib.annotations.Accessors

class DocElement {
  
  @Accessors(PACKAGE_GETTER)
  val List<Object> children = new ArrayList
  
  def void +=(Object child) {
    children += child
  }
  
  def Section section(String name, Procedure1<Section> init) { 
    val Section result = new Section(name) => init
    children += result
    return result
  }
  
  def Bullets orderedList(Procedure1<Bullets> init) {
    val Bullets result = new Bullets(true) => init
    children += result
    return result
  }
  
  def Bullets unorderedList(Procedure1<Bullets> init) {
    val Bullets result = new Bullets(false) => init
    children += result
    return result
  }
  
}
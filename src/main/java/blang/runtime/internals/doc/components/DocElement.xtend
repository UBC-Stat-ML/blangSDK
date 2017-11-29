package blang.runtime.internals.doc.components

import java.util.List
import java.util.ArrayList
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import blang.runtime.internals.doc.components.Code.Language
import org.eclipse.xtend.lib.annotations.Accessors

class DocElement {
  
  @Accessors(PUBLIC_GETTER)
  val List<Object> children = new ArrayList
  
  def void +=(Object child) {
    children += child
  }
  
  // TODO: getLabel, remember when called, etc
  
  def void section(String name, Procedure1<Section> init) { 
    children += new Section(name) => init
  }
  
  def void orderedList(Procedure1<Bullets> init) {
    children += new Bullets(true) => init
  }
  
  def void unorderedList(Procedure1<Bullets> init) {
    children += new Bullets(false) => init
  }
  
  def void code(Language language, String contents) {
    children += new Code(language, contents)
  }
  
}
package blang.runtime.internals.doc.components

import java.util.List
import java.util.ArrayList
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import blang.runtime.internals.doc.components.Code.Language
import java.util.Map
import java.util.HashMap

class DocElement {
  
  public val List<Object> children = new ArrayList
  
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
  
  def void downloadButton(Procedure1<DownloadButton> init) {
    children += new DownloadButton => init
  }
  
  val static public SYMB = "__SYMB"
  val static public ENDSYMB = "__ENDSYMB"
  
//  val public static _LINK = "__LINK"
//  public val Map<String, LinkTarget> _linkTargets = new HashMap
//  def LINK(LinkTarget target) {
//    val code = _LINK + "(" + target.hashCode + ")"
//    _linkTargets.put(code, target)
//    return code
//  }
//  val public ENDLINK = "__ENDLINK"
}
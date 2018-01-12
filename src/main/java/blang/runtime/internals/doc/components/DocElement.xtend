package blang.runtime.internals.doc.components

import java.util.List
import java.util.ArrayList
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import blang.runtime.internals.doc.components.Code.Language

abstract class DocElement {
  
  protected var List<Object> children = new ArrayList
  private val Procedure1 documentSpecification
  private var Renderer renderer = null
  
  private static class EmptyRenderer implements Renderer {
    override render(Object object) { "" }
  }
  
  new(Procedure1<? extends DocElement> documentSpecification) {
    this.documentSpecification = documentSpecification
    render(new EmptyRenderer)
  }
  
  def String render(Renderer renderer) {
    this.renderer = renderer
    children = new ArrayList
    documentSpecification.apply(this)
    return renderer.render(this)
  }
  
  // For use in init blocks [ ... ]
  
  def +=(Object child) {
    children.add(child)
  }
  
  def void section(String name, Procedure1<Section> init) { 
    children += new Section(init, name) 
  }
  
  def void orderedList(Procedure1<Bullets> init) {
    children += new Bullets(init, true)
  }
  
  def void unorderedList(Procedure1<Bullets> init) {
    children += new Bullets(init, false)
  }
  
  def void code(Language language, String contents) {
    children += new Code(language, contents)
  }
  
  def void downloadButton(Procedure1<DownloadButton> init) {
    children += new DownloadButton => init
  }
  
  // For use directly in string blocks e.g. '''  <<SYMB>> ..  ''' etc
  
  def String LINK(LinkTarget target) {
    renderer.render(new Link(target))
  }
  
  def String LINK(String target) {
    LINK(LinkTarget::url(target)) 
  }
  
  val static public Object _ENDLINK = new Object
  def String ENDLINK() {
    renderer.render(_ENDLINK)
  }
  
  val static public Object _SYMB = new Object
  def String SYMB() {
    renderer.render(_SYMB)
  }
  
  val static public Object _ENDSYMB = new Object
  def String ENDSYMB() {
    renderer.render(_ENDSYMB)
  }
  
  val static public Object _MATH = new Object
  def String MATH() {
    renderer.render(_MATH)
  }
  
  val static public Object _ENDMATH = new Object
  def String ENDMATH() {
    renderer.render(_ENDMATH)
  }
  
  val static public Object _EQN = new Object
  def String EQN() {
    renderer.render(_EQN)
  }
  
  val static public Object _ENDEQN = new Object
  def String ENDEQN() {
    renderer.render(_ENDEQN)
  }
  
  val static public Object _EMPH = new Object
  def String EMPH() {
    renderer.render(_EMPH)
  }
  
  val static public Object _ENDEMPH = new Object
  def String ENDEMPH() {
    renderer.render(_ENDEMPH)
  }
}
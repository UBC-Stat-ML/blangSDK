package blang.runtime.internals.doc.html

import java.util.List
import java.util.ArrayList
import briefj.ReflexionUtils
import java.lang.reflect.Field
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

abstract class Tag {
  
  @Attribute 
  public String id
  
  @Attribute 
  public String role
  
  @Attribute(name = "class") 
  public String cla
  
  public val List in = new ArrayList
  
  def a(Procedure1<A> init) { in += new A => init }
  def div(Procedure1<? super Div> init) { in += new Div => init }
  def li(Procedure1<Li> init) { in += new Li => init }
  def nav(Procedure1<Nav> init) { in += new Nav => init } 
  def ul(Procedure1<Ul> init) { in += new Ul => init }
  def h1(Procedure1<H1> init) { in += new H1 => init }
  def h2(Procedure1<H2> init) { in += new H2 => init }
  def h3(Procedure1<H3> init) { in += new H3 => init }
  
  val List<Pair<String,String>> additionalAttributes = new ArrayList 
  
  def void add(Pair<String,String> attribute) {
    additionalAttributes.add(attribute)
  }
  
  def private String render(Pair att) {
    '''«att.key.toString»="«att.value.toString»"'''
  }
  
  override String toString() {
    val String name = this.class.simpleName.toLowerCase
    val List<String> renderedProperties = new ArrayList
    for (Field f : ReflexionUtils::getDeclaredFields(this.class, true)) {
      if (f.getAnnotation(Attribute) !== null) {
        var String attName = f.getAnnotation(Attribute).name
        if (attName == "") {
          attName = f.name
        }
        val Object value = f.get(this)
        if (value !== null) {
          renderedProperties += render(attName -> value)
        }
      }
    }
    for (Pair<String,String> att : additionalAttributes) {
      renderedProperties += att.render
    }
    return '''
      <«name» «renderedProperties.join(" ")»>
        «FOR child : in»
          «child»
        «ENDFOR»
      </«name»>
    '''
  }
}
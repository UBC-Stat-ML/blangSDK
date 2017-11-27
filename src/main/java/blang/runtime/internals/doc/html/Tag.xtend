package blang.runtime.internals.doc.html

import java.util.List
import java.util.ArrayList
import briefj.ReflexionUtils
import java.lang.reflect.Field

abstract class Tag {
  
  @Attribute 
  public String id
  
  @Attribute 
  public String role
  
  @Attribute(name = "class") 
  public String cla
  
  public val List in = new ArrayList
  
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
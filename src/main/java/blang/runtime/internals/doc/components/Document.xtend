package blang.runtime.internals.doc.components

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

@Data
class Document extends DocElement {
  protected val String name
  
  def static Document create(String name, Procedure1<Document> init) {
    val Document result = new Document(name) => init
    return result
  }
}
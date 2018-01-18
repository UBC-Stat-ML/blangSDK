package blang.runtime.internals.doc.components

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

@Data
class Section extends DocElement {
  val String name
  
  new(String name, Procedure1<? extends Section> init) {
    super(init)
    this.name = name
  }
}
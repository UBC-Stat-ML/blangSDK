package blang.runtime.internals.doc.components

import org.eclipse.xtend.lib.annotations.Data
import java.util.ArrayList
import java.util.List

@Data
class MiniDoc {
  val String declaration
  val String doc
  val List<MiniDoc> children = new ArrayList
  new (String declaration, String doc) {
    this.declaration = declaration
    this.doc = doc
  }
}
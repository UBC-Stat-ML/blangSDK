package blang.runtime.internals.doc.components

import org.eclipse.xtend.lib.annotations.Data

@Data
class Code {
  val Language language
  val String contents
  static enum Language { blang, java, sh }
}
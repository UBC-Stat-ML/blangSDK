package blang.runtime.internals.doc.components

import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

class Document extends DocElement implements LinkTarget {
  public val String name
  public var String category
  public var boolean isIndex
  new(String name, Procedure1<? extends Document> init) { 
    super(init)
    this.name = name
  }
}
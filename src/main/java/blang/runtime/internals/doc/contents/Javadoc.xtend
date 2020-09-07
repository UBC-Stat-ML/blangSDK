package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories


class Javadoc {
  
  public val static Document page = new Document("Javadoc") [
    
    category = Categories::reference
    
    unorderedList[
      it += '''«LINK("javadoc-inits/index.html")»Inits JavaDoc«ENDLINK»'''
      it += '''«LINK("javadoc-dsl/index.html")»Blang DSL JavaDoc«ENDLINK»'''
      it += '''«LINK("javadoc-sdk/index.html")»Blang SDK JavaDoc«ENDLINK»'''
      it += '''«LINK("javadoc-xlinear/index.html")»xlinear JavaDoc«ENDLINK»'''
    ]
  ]
  
}
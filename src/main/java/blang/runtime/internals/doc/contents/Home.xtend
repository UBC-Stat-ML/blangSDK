package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document

import static extension blang.runtime.internals.doc.contents.DocElementExtensions.*
import blang.distributions.Dirichlet
import blang.runtime.internals.objectgraph.Node

class Home {
  
  public val static Document page = Document.create("Home") [
    
    
    section("One minute tour") [ 
      
      code(Dirichlet)
      
      
      
    ]
    
    // Example: Something involving normalization constants?
    
    // TODO: some motivation ideally mostly linked to the example above
    
    // TODO: quick start here?
    
  ]
  
}
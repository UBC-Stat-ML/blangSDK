package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import static extension blang.runtime.internals.doc.DocElementExtensions.documentClass
import blang.types.ExtensionUtils
import blang.types.StaticUtils

class CommonTypes {
  
  public val static Document page = new Document("Useful types") [
    
    category = Categories::reference
    
    it += '''Under construction!'''
    
    
    
    section("Testing") [
      
    ]
    
    section("Utilities") [
      documentClass(StaticUtils)
      documentClass(ExtensionUtils)
    ]
    
    section("IO") [
      
    ]
    
    section("MCMC moves") [
      
    ]
    
    section("Sampling engines") [
      
    ]
    
    section("Runtime") [
      
    ]
    
    section("MCMC") [
      
    ]
    
  ]
  

  
  
}
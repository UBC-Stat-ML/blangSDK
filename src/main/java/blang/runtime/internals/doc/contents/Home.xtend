package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document

import static extension blang.runtime.internals.doc.contents.DocElementExtensions.*
import blang.distributions.Dirichlet
import blang.distributions.Bernoulli
import blang.runtime.internals.objectgraph.Node

class Home {
  
  public val static Document page = Document.create("Home") [
    
    it += '''
      Blang is a language and software development kit for doing Bayesian analysis. 
      Our design philosophy is centered around the day-to-day requirements of real world 
      data analysis. We have also used Blang as a teaching tool, both for basic probability 
      concepts and more advanced Bayesian modelling. 
    '''
    
    section("Examples") [ 
      
      it += '''Here is an example:'''
      
      code(Dirichlet)
      
      it += '''Here is another one:'''
      
      code(Node)
      
    ]
    
    // Example: Something involving normalization constants?
    
    // TODO: some motivation ideally mostly linked to the example above
    
    // TODO: quick start here?
    
  ]
  
}
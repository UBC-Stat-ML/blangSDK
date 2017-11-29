package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document

class Home {
  
  public val static Document page = Document.create("Home") [
    
    it += '''
      Blang is a language and software development kit for doing Bayesian analysis. 
      Our design philosophy is centered around the day-to-day requirements of real world 
      data analysis. We have also used Blang as a teaching tool, both for basic probability 
      concepts and more advanced Bayesian modelling. 
    '''
    
    // Example: Something involving normalization constants?
    
    // TODO: some motivation ideally mostly linked to the example above
    
    // TODO: quick start here?
    
  ]
  
}
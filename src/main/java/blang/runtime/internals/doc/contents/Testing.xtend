package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import blang.TestSDKNormalizations

import static extension blang.runtime.internals.doc.DocElementExtensions.code

class Testing {
  
  public val static Document page = new Document("Testing Blang models") [
    
    category = Categories::reference
    
    it += '''
      Blang provides a battery of test to ensure correctness of the SDK. 
      These tests can also readily be used to test user-defined distributions, types and samplers. 
    '''
    
    section("Normalization tests") [
      it += '''
        For individual univariate continuous distributions, this check that the normalization is one.
      '''
      code(TestSDKNormalizations)
    ]
  ]
  
}
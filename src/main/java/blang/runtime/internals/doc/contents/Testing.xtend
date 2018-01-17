package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import blang.TestSDKNormalizations

import static extension blang.runtime.internals.doc.DocElementExtensions.code
import blang.validation.UnbiasnessTest

class Testing {
  
  public val static Document page = new Document("Testing Blang models") [
    
    category = Categories::reference
    
    section("Testing correctness: overview") [
    
      it += '''
        Blang provides a battery of test to ensure correctness of the SDK. 
        These tests can also readily be used to test user-defined distributions, types and samplers. 
      '''
    
    ]
    
    section("Testing strategies") [
    
      section("Exhaustive tests") [
        it += '''
          We provide a non-standard replacement implementation of 
          «LINK("https://github.com/alexandrebouchard/bayonet/blob/master/src/main/java/bayonet/distributions/Random.java")»bayonet.distributions.Random«ENDLINK» 
          which can be used to enumerates all the probability traces of a discrete probability models. 
          See «LINK("https://github.com/alexandrebouchard/bayonet/blob/master/src/main/java/bayonet/distributions/ExhaustiveDebugRandom.java")»bayonet.distributions.ExhaustiveRandom«ENDLINK».
          
          We use this for example to test the unbiasness of the normalization constant estimate provided by our 
          SMC implementation. 
        '''
        code(UnbiasnessTest)
        it += '''
          This can be called with a small finite model, e.g. a short HMM, only checking it is large enough to achieve code coverage.
        '''
      ]
      
      section("Normalization tests") [
        it += '''
          For individual univariate continuous distributions, this check that the normalization is one.
        '''
        code(TestSDKNormalizations)
      ]
    ]
  ]
  
}
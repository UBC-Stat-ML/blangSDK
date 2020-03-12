package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories

class CreatingTypes {
  
  public val static Document page = new Document("Creating random types") [
    
    category = Categories::reference
    
    section("Creating new types: overview") [
      it += '''
        The basic steps involved to create custom types are described in 
        the «LINK(GettingStarted::page)»Getting Started page«ENDLINK». 
        
        To handle more complicated cases, read the following:
      '''
      unorderedList[
        it += '''
          In the «LINK(InferenceAndRuntime::page)»Inference and 
          Runtime page«ENDLINK», you can find how custom samplers are 
          automatically matched to target types.
        '''
        it += '''
          In the «LINK(InputOutput::page)»Input and Output page«ENDLINK», 
          you can find how to load observations for the custom types, and 
          how to output samples.
        '''
        it += '''
          In the «LINK(Testing::page)»Testing page«ENDLINK», you can find 
          information on setting automated tests to check correctness of your 
          implementation.
        '''
      ]
      it += '''
        Also consider transforming the problem of sampling your new type into 
        a problem that can be handled using built-in sampler, which include:
      '''
      orderedList[
        it += '''
          «SYMB»RealSliceSampler«ENDSYMB»: implementation of the Slice Sampler 
          «LINK("https://projecteuclid.org/download/pdf_1/euclid.aos/1056562461")»(Neal, 2003)«ENDLINK» 
          with doubling and shrinking. A fixed starting interval can also be provided 
          if only the shrinking procedure is required (for example this second 
          variant is used internally for simplex sampling in «SYMB»SimplexSampler«ENDSYMB»).
        '''
        it += '''
          «SYMB»IntSliceSampler«ENDSYMB»: which provides the same facilities as 
          above but for integers. The fixed starting variant is used internally in 
          categorical realization sampling, «SYMB»CategoricalSampler«ENDSYMB».
        '''
        it += '''
          «SYMB»MHSampler«ENDSYMB»: an abstract class providing a basis for custom 
          Metropolis-Hastings samplers. See  
          «SYMB»blang.validation.internals.fixtures.IntNaiveSampler«ENDSYMB» for an example.
        '''
      ]
    ]
  ]
  
}
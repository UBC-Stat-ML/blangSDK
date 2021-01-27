package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.validation.internals.fixtures.MarkovChain

import static extension blang.xdoc.DocElementExtensions.code
import blang.validation.internals.fixtures.DynamicNormalMixture
import blang.validation.internals.fixtures.SpikeAndSlab
import blang.validation.internals.fixtures.SpikedGLM
import blang.validation.internals.fixtures.Ising
import blang.types.SpikedRealVar

class Examples {
  
  public val static Document page = new Document("Examples") [
    
    section("Examples") [
      
      section("Markov chains and HMMs") [
        
        // TODO: link to some background reading
        
        it += '''
          We start with a simple model for Markov chains:
        '''
        
        code(MarkovChain)
        
        it += '''
          Notice that we used the pre-computation construct, namely
          
          «SYMB»IntVar previous = chain.get(step - 1)«ENDSYMB»
          
          Accessing an array is not so much expensive, so you may wonder why we bothered pre-computing this. 
          It turns out there is actually an important speed gain to be made, of the order of the length of the chain. Why?
          
          To understand, we need to outline how the blang inference engines work under the hood. 
          Most of these engines exploit cases where conditional distributions only depend on subsets of the variables. 
          To do so, blang inspects the model constituents (for example the «SYMB»Categorical«ENDSYMB» constituents) to 
          infer what is the «EMPH»scope«ENDEMPH» of the constituent. A scope is simply the subset of the variables 
          available at a given location of the code (e.g. the code in one function cannot access the local variables 
          declared in another function, they are «EMPH»out of scope«ENDEMPH»). So coming back to the Markov chain example, 
          this means that by passing in the precomputed «SYMB»chain.get(step - 1)«ENDSYMB» rather than all the latent 
          variables, we make it possible for blang engines to infer that each time step in the HMM only have 
          interdependence with the previous and next state rather than all states. 
          In graphical model parlance, this means sparsity patterns in the graphical model are inferred.
          
          Let us look now how we can use a Markov chain as a building block for an HMM:
        '''
        
        code(DynamicNormalMixture)
        
      ]
      
      section("Ising models and other Markov random fields") [
        
        it += '''
          Undirected graphical models (AKA Markov random fields) are supported: here is 
          for example how a square Ising model is implemented:
        '''
        
        code(Ising) 
        
      ]
      
      section("Spike and Slab model") [
        
        // TODO: link to some background reading
        
        it += '''
          First, we create a custom data type:
        '''
        
        code(SpikedRealVar)
        
        
        
        it += '''
          We can now define a distribution for this type:
        '''
        
        code(SpikeAndSlab)
        
        it += '''
          Afterwards, it is easy to incorporate Spike and Slab priors in more complicated models, for example a 
          naive GLM here: 
        '''
        
        code(SpikedGLM)
        
      ]
      
    ]
  ]
  
}
package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories
import static extension blang.xdoc.DocElementExtensions.documentClass
import blang.types.DenseSimplex
import blang.types.DenseTransitionMatrix
import blang.types.StaticUtils
import blang.types.Plate
import blang.types.Plated
import blang.types.ExtensionUtils
import blang.distributions.Generators

class BuiltInRandomVariables {
  
  public val static Document page = new Document("Random variables") [
    
    category = Categories::reference
    
    section("Built-in random variables") [
    
      section("Built-in primitives") [
        it += '''
          The interfaces «SYMB»RealVar«ENDSYMB» and «SYMB»IntVar«ENDSYMB» are automatically imported. 
          As for most random variables, they can be either latent (unobserved, sampled), or fixed 
          (conditioned upon). 
          
          «SYMB»RealVar«ENDSYMB» and «SYMB»IntVar«ENDSYMB» are closely related to Java's «SYMB»Double«ENDSYMB» 
          and «SYMB»Integer«ENDSYMB» but 
          the former have implementations allowing mutability for the purpose of efficient sampling. 
          Java's «SYMB»Double«ENDSYMB» and «SYMB»Integer«ENDSYMB» are automatically converted back and forth 
          to «SYMB»RealVar«ENDSYMB» and «SYMB»IntVar«ENDSYMB» (some kind of generalization of 
          «LINK("https://docs.oracle.com/javase/tutorial/java/data/autoboxing.html")»auto-boxing«ENDLINK»). 
        '''
      ]
      
      section("Linear algebra") [
        it += '''
          Blang's linear algebra is based on «LINK("https://github.com/alexandrebouchard/xlinear")»xlinear«ENDLINK» 
          which is in turn based on a portfolio of established libraries. 
          
          The basic classes there are «SYMB»Matrix«ENDSYMB», «SYMB»DenseMatrix«ENDSYMB» and «SYMB»SparseMatrix«ENDSYMB». 
          Blang/XBase allows operator overloading, so you write expressions likes «SYMB»matrix1 * matrix2«ENDSYMB», 
          «SYMB»2.0 * matrix«ENDSYMB», etc. 
          Vectors do not have a distinct type, they are just 1-by-n or n-by-1 matrix. 
          Standard operations are supported using unsurprising syntaxes, e.g.  
          «SYMB»identity(100_000)«ENDSYMB», «SYMB»ones(3,3)«ENDSYMB» «SYMB»matrix.norm«ENDSYMB», «SYMB»matrix.sum«ENDSYMB», 
          «SYMB»matrix.readOnlyView«ENDSYMB», «SYMB»matrix.slice(1, 3, 0, 2)«ENDSYMB», 
          «SYMB»matrix.cholesky«ENDSYMB», etc. 
          See «LINK("https://github.com/alexandrebouchard/xlinear")»xlinear«ENDLINK» for more info.
          
          xlinear is augmented in Blang with the following types:
        '''
        documentClass(DenseSimplex)
        documentClass(DenseTransitionMatrix)
      ]
      
      section("Initialization of random variables") [
        it += '''
          If a variable is only declared, as in «SYMB»random RealVar myVariable«ENDSYMB» or 
          «SYMB»param RealVar myVariable«ENDSYMB», then it will be initialized using the command line 
          arguments with prefix «SYMB»model.myVariable«ENDSYMB». 
          Use «SYMB»--help«ENDSYMB» to see the list of arguments. How to customize this 
          behaviour is describe «LINK(InputOutput::page)»here«ENDLINK».
          
          If a variable is provided with a default value, as in «SYMB»random RealVar myVariable ?: fixedReal(42.0)«ENDSYMB» 
          or «SYMB»param RealVar myVariable ?: { /* init block */ }«ENDSYMB», then the initialization block will be used whenever 
          no command line arguments are provided for this variable. The following are useful for creating initialization blocks:
        '''
        documentClass(StaticUtils)
        documentClass(ExtensionUtils)
      ]
    ]
    
    section("Collections of random variables") [
      it += '''
        As hinted in «SYMB»StaticUtils«ENDSYMB» above, simple collections of random variables can be achieved using Java built-in 
        List objects. However in more complex scenarios we need random variables indexed by several plates. 
      '''      
      documentClass(Plate)
      documentClass(Plated)
    ]
    
    section("Generation of random variables") [
      it += '''
        For random generation, Blang uses «SYMB»bayonet.distributions.Random«ENDSYMB», a replacement for 
        «SYMB»java.util.Random«ENDSYMB» which by default uses under the hood 
        the Math Commons implementation of MarsenneTwister and is compatible both with Java and Math Commons 
        random types. 
        
        To generate specific distributions, use «SYMB»blang.distributions.Generators«ENDSYMB», the methods of 
        which are automatically imported in Blang model as static extensions, meaning for example to generate 
        a gamma you can just write «SYMB»rand.gamma(shape, rate)«ENDSYMB».
      '''
      documentClass(Generators)
    ]
    
  ]
}
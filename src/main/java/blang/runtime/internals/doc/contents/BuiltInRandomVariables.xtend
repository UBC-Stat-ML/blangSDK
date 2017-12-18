package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import static extension blang.runtime.internals.doc.DocElementExtensions.documentClass
import blang.types.DenseSimplex
import blang.types.DenseTransitionMatrix
import blang.types.ExtensionUtils
import blang.types.StaticUtils

class BuiltInRandomVariables {
  
  public val static Document page = new Document("Built-in random variables") [
    
    category = Categories::reference
    
    section("Primitives") [
      it += '''
        The interfaces «SYMB»RealVar«ENDSYMB» and «SYMB»IntVar«ENDSYMB» are automatically imported. 
        As for most random variables, they can be either latent (unobserved, sampled), or constant 
        (observed, fixed). 
        
        «SYMB»RealVar«ENDSYMB» and «SYMB»IntVar«ENDSYMB» are closely related to Java's «SYMB»Double«ENDSYMB» 
        and «SYMB»Integer«ENDSYMB» but 
        the latter have implementations allowing mutability for the purpose of efficient sampling. 
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
        «SYMB»identity(100_000)«ENDSYMB», «SYMB»ones(3,3)«ENDSYMB» «SYMB»norm(matrix)«ENDSYMB», «SYMB»sum(matrix)«ENDSYMB», 
        «SYMB»matrix.readOnlyView«ENDSYMB», «SYMB»matrix.slice(1, 3, 0, 2)«ENDSYMB», 
        «SYMB»matrix.cholesky«ENDSYMB», etc. 
        See «LINK("https://github.com/alexandrebouchard/xlinear")»xlinear«ENDLINK» for more info.
        
        xlinear is augmented in Blang with the following types:
      '''
      documentClass(DenseSimplex)
      documentClass(DenseTransitionMatrix)
    ]
    
    section("Creating random variables") [
      
    ]
    
    section("Plates") [
      
    ]
    
    
    
    section("Utilities") [
      documentClass(StaticUtils)
      documentClass(ExtensionUtils)
    ]
    
    
    
  ]
  

  
  
}
package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories

class BuiltInFunctions {
  
  public val static Document page = new Document("Functions") [
    
    category = Categories::reference
    
    it += '''
      Any Java function can be called. Those from the sources below are automatically statically imported 
      for easy access. We only show the most useful ones.
    '''

    unorderedList[
      it += '''
        «LINK("https://docs.oracle.com/javase/8/docs/api/java/lang/Math.html")»From java.lang.Math«ENDLINK»: 
        (note that all trigonometric operations use angles expressed in radian)
      '''
      
      unorderedList[
        it += '''«SYMB»double abs(double value)«ENDSYMB»,'''
        it += '''«SYMB»double  acos(double a)«ENDSYMB» (arc cosine),'''
        it += '''«SYMB»double  asin(double a)«ENDSYMB»,'''
        it += '''«SYMB»double  atan(double a)«ENDSYMB»,'''
        it += '''«SYMB»double  cbrt(double a)«ENDSYMB» (cube root),'''
        it += '''«SYMB»double  ceil(double a)«ENDSYMB» (ceiling),'''
        it += '''«SYMB»double  cos(double a)«ENDSYMB» (cosine),'''
        it += '''«SYMB»double  cosh(double x)«ENDSYMB» (hyperbolic cosine),'''
        it += '''«SYMB»double  exp(double a)«ENDSYMB» (exponential base e),'''
        it += '''«SYMB»double  floor(double a)«ENDSYMB» (floor),'''
        it += '''«SYMB»double  log(double a)«ENDSYMB» (logarithm base e),'''
        it += '''«SYMB»double  log10(double a)«ENDSYMB» (logarithm base 10),'''
        it += '''«SYMB»double  max(double a, double b)«ENDSYMB»,''' 
        it += '''«SYMB»double  min(double a, double b)«ENDSYMB»,'''
        it += '''«SYMB»double  pow(double a, double b) (a to the power b)«ENDSYMB»,'''
        it += '''«SYMB»double  signum(double d)«ENDSYMB»,'''
        it += '''«SYMB»double  sin(double a)«ENDSYMB»,'''
        it += '''«SYMB»double  sinh(double x)«ENDSYMB»,'''
        it += '''«SYMB»double  sqrt(double a) (square root)«ENDSYMB»,'''
        it += '''«SYMB»double  tan(double a)«ENDSYMB»,'''
        it += '''«SYMB»double  tanh(double x)«ENDSYMB»,'''
        it += '''«SYMB»E«ENDSYMB»,'''
        it += '''«SYMB»PI«ENDSYMB».'''
      ]
    ]
    
    unorderedList[
      it += '''
        «LINK("https://github.com/alexandrebouchard/bayonet/blob/master/src/main/java/bayonet/math/SpecialFunctions.java")»From bayonet.math.SpecialFunctions«ENDLINK»: 
      '''
      
      unorderedList[
        it += '''«SYMB»double erf(double x)«ENDSYMB» (error function),'''
        it += '''«SYMB»double inverseErf(double z)«ENDSYMB»,''' 
        it += '''«SYMB»double logistic(double x)«ENDSYMB»,'''
        it += '''«SYMB»double logit(double x)«ENDSYMB»,'''
        it += '''«SYMB»double logBinomial(int n, int k)«ENDSYMB»,'''
        it += '''«SYMB»double lnGamma(double alpha)«ENDSYMB»,'''
        it += '''«SYMB»double logFactorial(int input)«ENDSYMB»,''' 
        it += '''«SYMB»double multivariateLogGamma(int dim, double a)«ENDSYMB» («LINK("http://en.wikipedia.org/wiki/Multivariate_gamma_function")»Multivariate Gamma function«ENDLINK»).'''
      ]
    ]
    
    it += '''
      Some common operations are also defined as methods or extensions and are documented in the «LINK(BuiltInRandomVariables::page)»page on built-in types«ENDLINK».
    '''
  ]
}
package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import blang.engines.internals.PosteriorInferenceEngine

import static extension blang.runtime.internals.doc.DocElementExtensions.code
import blang.runtime.internals.doc.DocElementExtensions
import blang.runtime.internals.doc.components.Code.Language

class InputOutput {
  
  public val static Document page = new Document("Input and output") [
    
    category = Categories::reference
    
    section("Input and output: overview") [
      it += '''
        In this page, we cover
      '''
      orderedList[
        it += '''
          Input: how to load data. This is used for:
        '''
        orderedList[
          it += '''
             fixing random variables' value to 
             a given  value, i.e. conditioning on that value or observation,
          '''
          it += '''
             setting the parameters of models,
          '''
          it += '''
             setting the parameters of inference algorithms.
          '''
        ]
        it += '''
          Output: how to control the output  of samples when custom 
          types are used. 
        '''
      ]
    ]
    
    section("Input") [
      it += '''
        Inputs are controlled using the injection framework 
        «LINK("https://github.com/UBC-Stat-ML/inits/")»inits«ENDLINK» 
        which is designed for dependency injection in the context of 
        scientific models. 
        
        To summarize, instantiation of arbitrary types is approached recursively with these 
        main schemes:
      '''
      unorderedList[
        it += '''
          When instantiating a class:
        '''
        unorderedList[
          it += '''
            A constructor or static factory is selected by looking 
            for the annotation «SYMB»@ProvidesFactory«ENDSYMB» in the file declaring the custom 
            type. See also the class «SYMB»Parsers«ENDSYMB» 
            which contains examples for basic types e.g. those from the 
            JVM or from xlinear. As a fall-back default, using a no-argument 
            constructor, if available, will be attempted.
          '''
          it += '''
            Each argument in this constructor or static factories should be annotated 
            as follows:
          '''
          orderedList[
            it += '''
              For arguments to be read from the command line, use 
              «SYMB»@ConstructorArg(value = "nameOfArg")«ENDSYMB». The type of each 
              argument will be recursively inspected to figure out how to parse it.
            '''
            it += '''
              To bootstrap the process, you can also declare an argument 
              «SYMB»@Input String string«ENDSYMB» or «SYMB»@Input List<String> strings«ENDSYMB»
              and parse that provided string or strings manually.
            '''
            it += '''
              To mark certain entries as observed, you can 
              make the random variable immutable. 
              Alternatively, you can mark 
              subgraphs of the accessibility graph as observed by 
              declaring a constructor argument 
              «SYMB»@GlobalArg Observations initContext«ENDSYMB» and
              then calling «SYMB»initContext.markAsObserved(object)«ENDSYMB».
            '''
            it += '''
              To recursively parse other string to be converted to 
              arbitrary types, declare a constructor argument 
              «SYMB»@InitService Creator creator«ENDSYMB» and call 
              «SYMB»creator.init(type, arguments)«ENDSYMB» where 
              type can be a class or «SYMB»TypeLiteral«ENDSYMB», and 
              arguments can be obtained via «SYMB»SimpleParser.parse(string)«ENDSYMB» 
              in most cases.
            '''
          ]
          it += '''
            As a short-hand, it is also possible to annotate fields 
            with «SYMB»@Arg«ENDSYMB», this will cause them to be 
            populated automatically after calling the constructor or 
            static factory. 
          '''
          it += '''
            Both for «SYMB»@Arg«ENDSYMB» and «SYMB»@ConstructorArg«ENDSYMB», 
            you can give default value to arguments via 
            «SYMB»@DefaultValue«ENDSYMB», or make it optional by enclosing the 
            declared types into an «SYMB»Optional<..>«ENDSYMB».
          '''
        ]
        it += '''
          When instantiating an interface, the following is also available:
        '''
        unorderedList[
          it += '''
            Add the annotation «SYMB»@Implementations«ENDSYMB» to the interface, 
            with a list of comma-separated implementations. 
          '''
          it += '''
            Then use the annotations «SYMB»@Arg«ENDSYMB» and «SYMB»@ConstructorArg«ENDSYMB» 
            as described above for each possible implementation.
          '''
        ]
        it += '''
          Enumerations (enum) are taken care of automatically. 
        '''
      ]
      it += '''
        As a convention, we use the string «SYMB»NA«ENDSYMB» to 
        mean unobserved (latent). This string can be accessed 
        in a type safe manner via «SYMB»NA:SYMBOL«ENDSYMB».
                  
        After following this procedure, argument parsing is automatically taken 
        care of. Naming of switches is done hierarchically. 

        Here is a concrete example to show how it works. In blang's main 
        class, there is an annotated field «SYMB»@Arg PosteriorInferenceEngine engine«ENDSYMB». 
        This type declares the following implementations:
      '''
      code(PosteriorInferenceEngine)
      it += '''
        Now let's look at one of those implementations, say SCM. SCM's parent class 
        is AdaptiveJarzynski, which declares «SYMB»@Arg Cores nThreads«ENDSYMB». 
        
        In turn, the «SYMB»Core«ENDSYMB» declares the following static factory:
      '''
      code(Language.java, '''
        @DesignatedConstructor
        public Cores(
          @Input(formatDescription = "Integer - skip or " + MAX + " to use max available") 
          Optional<String> input) {
            ...
        }
      ''')
      it += '''
        This creates the following command line options (described here by a snippet of 
        what is produced by «SYMB»--help«ENDSYMB»:
      '''
      code(Language.text, '''
         --engine <PosteriorInferenceEngine: SCM|PT|Forward|Exact|None|fully qualified> (default value: SCM)
         
         --engine.nThreads <Cores: Integer - skip or MAX to use max available> (mandatory)
      ''')
    ]
    
    section("Output") [
      
    ]
  ]
  
}
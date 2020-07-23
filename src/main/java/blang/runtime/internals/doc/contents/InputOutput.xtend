package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories
import blang.engines.internals.PosteriorInferenceEngine

import static extension blang.xdoc.DocElementExtensions.code
import blang.xdoc.components.Code.Language
import blang.runtime.Runner

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
             fixing a random variable's value to 
             a given observation (conditioning),
          '''
          it += '''
             setting the hyper-parameters of models,
          '''
          it += '''
             setting the tuning parameters of inference algorithms.
          '''
        ]
        it += '''
          Output: how to control the output  of samples when custom 
          types are used. 
        '''
      ]
    ]
    
    section("Input") [
      
      section("Customization of the input when creating new types") [
        it += '''
          Inputs are controlled using the injection framework 
          «LINK("https://github.com/UBC-Stat-ML/inits/")»inits«ENDLINK» 
          which is designed for dependency injection in the context of 
          scientific models. This is entirely automatic for existing Blang types, 
          only read this section if you want to create custom data types and 
          would like to condition on them, i.e. load data and fix the variable 
          to that loaded value.
          
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
                To recursively parse other strings to be converted to 
                arbitrary types, declare a constructor argument 
                «SYMB»@InitService Creator creator«ENDSYMB» and call 
                «SYMB»creator.init(type, arguments)«ENDSYMB» where 
                type can be a class literal (such as String, Integer) or an instance of «SYMB»TypeLiteral«ENDSYMB».  
                Arguments can be obtained via «SYMB»SimpleParser.parse(string)«ENDSYMB» 
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
              you can give a default value to the argument via 
              «SYMB»@DefaultValue«ENDSYMB», or make it optional by enclosing the 
              declared type into an «SYMB»Optional<..>«ENDSYMB».
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
              Then follow the above process for each implementation.
            '''
          ]
          it += '''
            Enumerations (enum) are taken care of automatically. 
          '''
        ]
        it += '''
          For more information, see the README.md file in the 
          «LINK("https://github.com/UBC-Stat-ML/inits/")»inits repository«ENDLINK».
        '''
      ]
      section("Missing data") [
        it += '''
          As a convention, we use the string «SYMB»NA«ENDSYMB» to 
          mean unobserved (latent). This string can be accessed 
          in a type safe manner via «SYMB»NA:SYMBOL«ENDSYMB».
        '''
      ]
      
      section("Providing arguments from the command line") [
        it += '''
          Argument parsing is automatically taken 
          care of (by introspection of the injection framework's annotations). 
          Naming of switches is done hierarchically. 
  
          Here is a concrete example to show how it works. In Blang's main 
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
           --engine <PosteriorInferenceEngine: SCM|PT|Forward|Exact|None|fully qualified>
           
           --engine.nThreads <Cores: Integer - skip or MAX to use max available>
        ''')
      ]
    ]
    
    section("Output") [
      
      section("Organization") [
        it += '''
          Every Blang execution creates a unique directory. The path is output to standard out at the end of the run. 
          The latest run is also softlinked at «SYMB»results/latest«ENDSYMB». 
          
          The directory has the following structure:
        '''
        unorderedList[
          it += '''
            «SYMB»«Runner.SAMPLES_FOLDER»/«ENDSYMB»: samples from the target distribution. By default each random variable in the 
            running model is output for each iteration (to disable for some variables, e.g. those that are fully 
            observed, use «SYMB»--excludeFromOutput«ENDSYMB»). We describe the format in more detail below.
          '''
          it += '''
            «SYMB»«Runner.LOG_NORMALIZATION_ESTIMATE».csv«ENDSYMB»«ENDSYMB»: estimate of the natural logarithm of the probability of the data 
            (also known as the log of the normalization constant of the prior times the likelihood, integrating over the latent). 
            Only available for certain inference engines such as SCM.
          '''
          it += '''
            «SYMB»arguments*«ENDSYMB»: arguments used in this run.
          '''
          it += '''
            «SYMB»executionInfo/«ENDSYMB»: additional information for reproducibility (JVM arguments, 
            standard out, etc). To automatically extract code version, use «SYMB»--experimentConfigs.recordGitInfo true«ENDSYMB».
          '''
          it += '''
            «SYMB»«Runner.MONITORING_FOLDER»/«ENDSYMB»: diagnostic for the samplers. 
          '''
        ]
      ]
      
      section("Format of the samples") [
        it += '''
          The samples are stored in tidy csv files. For example, two samples for a list of two RealVar's would look like:
        '''
        code(Language.text, '''
          index_0,sample,value
          0,0,0.45370104866569855
          1,0,0.38696647209956947
          2,0,0.42871560465749226
          0,1,0.5107038773755743
          1,1,0.34488603941828144
          2,1,0.40406618985385023
        ''')
        it += '''
          By default, the method «SYMB»toString«ENDSYMB» is used to create the last column (value). 
          This behaviour can be 
          customized to follow the tidy philosophy. To do so, implement the interface 
          «SYMB»TidilySerializable«ENDSYMB»  
          («LINK("https://github.com/UBC-Stat-ML/inits/blob/master/src/test/java/blang/inits/TestTidySerializer.xtend")»example available here«ENDLINK»).
        '''
      ]
      
      section("Output options") [
        it += '''
          The following command line arguments can be used to tune the output:
        '''
        unorderedList[
          it += '''
            «SYMB»--excludeFromOutput«ENDSYMB»: space separated list of random variables to exclude from output.
          '''
          it += '''
            «SYMB»--experimentConfigs.managedExecutionFolder«ENDSYMB»: set to false to output in the current folder instead of in the 
            unique folder created in results/all.
          '''
          it += '''
            «SYMB»--experimentConfigs.recordExecutionInfo«ENDSYMB»: set to false to skip recording reproducibility information 
            in executionInfo. 
          '''
          it += '''
            «SYMB»--experimentConfigs.recordGitInfo«ENDSYMB»: set to true to record git repo info for the code.
          '''
          it += '''
            «SYMB»--experimentConfigs.saveStandardStreams«ENDSYMB»: set to false to skip recording the standard out and err.
          '''
          it += '''
            «SYMB»--experimentConfigs.tabularWriter«ENDSYMB»: by default, «SYMB»CSV«ENDSYMB». Can set to «SYMB»Spark«ENDSYMB» to 
            organize tidy output into a hierarchy of directories each having a csv (with less column as many columns are in this format 
            now inferable from the names of the parent directories). In certain scenario this could save disk space. Inter-operable with 
            Spark. 
          '''
        ]
      ]
    ]
  ]
  
}
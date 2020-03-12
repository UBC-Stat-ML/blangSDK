package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document

import static extension blang.xdoc.DocElementExtensions.code
import blang.validation.internals.fixtures.Doomsday
import blang.xdoc.components.Code.Language
import blang.distributions.ContinuousUniform
import blang.distributions.Exponential
import blang.validation.internals.fixtures.HierarchicalModel
import blang.mcmc.SimplexSampler

class GettingStarted {
  
  public static val page = new Document("Getting started") [
    
    it += BlangIDE::installBlang
    
    section("Blang: a fifteen minutes tutorial") [
      
      it += '''While the download proceeds, here is short tutorial on Blang. '''

      section("Models") [
        it += '''A Blang «SYMB»model«ENDSYMB» specifies a joint probability distribution over a collection of random variables.'''
        it += '''
          Here is an example, based on a very simple model for the famous 
          «LINK("https://en.wikipedia.org/wiki/Doomsday_argument")»Doomsday argument«ENDLINK»:'''
        code(Doomsday) [ replaceAll("package [a-z.]*", "package demo") ]
        it += '''
          «SYMB»Doomsday«ENDSYMB» is a just a name we give to this model. As a convention, we encourage users to capitalize model names 
          (Blang is case-sensitive). '''
      ]
      
      section("Variables") [
        it += '''
          Variables need to specify their type, e.g.: «SYMB»random RealVar z«ENDSYMB» is of type «SYMB»RealVar«ENDSYMB» and
           we give it the name «SYMB»z«ENDSYMB». Some of the «LINK(BuiltInRandomVariables::page)»other important built-in types«ENDLINK» 
           are «SYMB»IntVar«ENDSYMB» and «SYMB»DenseMatrix«ENDSYMB». '''
        it += '''«SYMB»random«ENDSYMB» and «SYMB»param«ENDSYMB» are Blang keywords. We will get back to the difference between the two. '''
        it += '''As a convention, types are capitalized, variable names are not.''' 
      ]
      
      section("Laws") [
        it += '''
          The section «SYMB»laws { ... }«ENDSYMB» defines distribution and conditional distributions on the random variables. 
          The syntax is the same as the notation used in probability theory. For example, «SYMB»y | z ~ ContinuousUniform(0.0, z)«ENDSYMB» 
          means that the conditional distribution of «SYMB»y«ENDSYMB» given «SYMB»z«ENDSYMB» is uniformly distributed between zero and «SYMB»z«ENDSYMB».
          '''
      ]
      
      section("Performing inference") [ 
        it += '''
          Each Blang model is turned into a program supporting various inference methods. 
          To demonstrate that, let's run the above example. '''
        orderedList[
          it += '''
            Setup one of these two methods: 
            «LINK(BlangWeb::page)»running Blang with the Web App«ENDLINK», or 
            «LINK(BlangIDE::page)»with the Blang IDE«ENDLINK».''' 
          it += '''
            Once you follow the above steps, you will get a message about missing arguments. 
            These arguments essentially control the data the model should condition on, as well 
            as the algorithm used to approximate the conditional expectation (the 'inference engine').
            The arguments are automatically discovered with the minimal helps of some annotations. 
            We will cover that later. For now, let's provide the minimal set:'''
        ]
        code(Language.text, arguments)
        it += '''
          This specifies values for «SYMB»rate«ENDSYMB» and «SYMB»y«ENDSYMB», and mark «SYMB»z«ENDSYMB» as 
          missing (unobserved, and hence sampled over). You will see the following output'''
        code(Language.text, result)
        it += '''
          The most important piece of information here is the «SYMB»outputFolder«ENDSYMB». 
          Look into that directory. You will find in «SYMB»samples/z.csv«ENDSYMB» the samples in a tidy format, 
          ready to be used by any sane data analytic tool.
        ''' 
        it += '''You can also view the list of all arguments by adding the argument «SYMB»--help«ENDSYMB».'''
      ]
      
      section("Creating distributions") [
        it += '''
          Let's look at how «SYMB»ContinuousUniform«ENDSYMB» is implemented in the SDK. Since the SDK is written 
          in Blang, you will proceed in the exact same way to create yours. Control click on «SYMB»ContinuousUniform«ENDSYMB» 
          in Blang IDE, you will be taken to its definition:
        '''
        code(ContinuousUniform)
        it += '''
          The syntax should be self-explanatory: '''
        unorderedList[
          it += '''
            the «SYMB»laws«ENDSYMB» block defines the density as the sum of the log density «EMPH»factors«ENDEMPH»  
            «SYMB»logf«ENDSYMB» listed («SYMB»indicator«ENDSYMB» is just a shortcut for 0-1 factors),'''
          it += '''
            the optional «SYMB»generate«ENDSYMB» block specifies a forward sampling procedure. 
          ''' 
        ]
        it += '''
          The body of «SYMB»logf«ENDSYMB», «SYMB»indicator«ENDSYMB», and «SYMB»generate«ENDSYMB» 
          admit a rich and concise, Turing-complete syntax. We will refer to such block as an 
          XExpression. We will talk more about it later on. 
        ''' 
        it += '''
          Another important method for creating models is by composing and transforming one or several 
          other distribution. Look at the definition of «SYMB»Exponential«ENDSYMB» for example:
        '''
        code(Exponential)
        it += '''
          For both models constructed using an explicit density (like «SYMB»ContinuousUniform«ENDSYMB»), and 
          those constructed by composition (like «SYMB»Exponential«ENDSYMB»), we invoke them in the same way:
        '''
        code(Language.blang, '''
          randomVariable1, ... | conditioning ~ NameOfModel(parameter1, ...)
        ''') 
        it += '''
          where the random variables are listed in the same order as the variables marked by the keyword 
          «SYMB»random«ENDSYMB» appear in the invoked model definition, and the parameters are listed in the same 
          order a the variables marked by the keyword «SYMB»param«ENDSYMB».
        '''
        it += '''
          To create your own distribution, simply create a new «SYMB».bl«ENDSYMB» file in your project. 
          When you want to use it in another file, don't forget to add an import declaration after the 
          package declaration (only certain packages are automatically imported, such as «SYMB»blang.distributions«ENDSYMB»).
        '''
      ]
      
      section("Plates") [
        it += '''
          A plate is simply an element of a graphical model which is repeated many times. Let's look for example at a simple 
          hierarchical modelling problem: suppose you have a data file «SYMB»failure_counts.csv«ENDSYMB» of this form
        '''
        code(Language.text, dataFileTop)
        it += '''
          Each row contains a Launch Vehicle (LV) type, and the number of successful launches for that type of rocket, as well 
          as the total number of launches. We would like to get a posterior distribution over the failure probability of each 
          LV type via a hierarchical model that borrows strength across types. Here is a Blang model that does that:
        '''
        code(HierarchicalModel)
        it += '''
          The for loop here uses plates and plated objects to set up a large graphical models. More generally, the syntax is 
          «SYMB»for (IteratorType iteratorName : collection) { ... }«ENDSYMB», where «SYMB»collection«ENDSYMB» is any instance of the  
          «LINK("https://docs.oracle.com/javase/8/docs/api/java/lang/Iterable.html")»Iterable«ENDLINK» interface.
        '''
        it += '''
          To run the HierarchicalModel example, use the following options:
        '''
        code(Language.text, hierarchicalModelOpts)
        it += '''
          The first option correspond to the line «SYMB»param GlobalDataSource data«ENDSYMB» in the Blang model. This provides a 
          default csv file to look for data for all the «SYMB»Plate«ENDSYMB» and «SYMB»Plated«ENDSYMB» variables (a "Plated" 
          type is just a variable that sits within a plate, i.e. that is repeated).
        '''
        it += '''
          By default, all the «SYMB»Plate«ENDSYMB» and «SYMB»Plated«ENDSYMB» will look for a column with a name corresponding to the 
          one given in the Blang file. We only need to override this default for the «SYMB»rocketTypes«ENDSYMB» plate, by setting 
          the command line argument «SYMB»--model.rocketTypes.name LV.Type«ENDSYMB».
        '''
      ]
      
      section("Creating new types") [
        it += '''
          Arbitrary Java or Xtend types are inter-operable with Blang. When you want to use them as latent variables, some 
          additional work is needed. However Blang provides utilities to assist you in this process, in particular for testing correctness.  
        '''
        it += '''
          As a first example, let's look at how sampling is implemented for «SYMB»Simplex«ENDSYMB» variables in the SDK (i.e. 
          vectors where the entries are constrained to sum to one). 
          Sampling this variable requires special attention because of the sum to one constraint. 
        '''
        it += '''
          After implementing the class «SYMB»DenseSimplex«ENDSYMB» (just a plain Java class, based on a n-by-1 matrix), we add an 
          annotation to point to the sampler that we will design: «SYMB»@Samplers(SimplexSampler)«ENDSYMB». 
        '''
        it += '''
          Here is the sampler:
        '''
        code(SimplexSampler)
        unorderedList[
          it += '''
            The actual work is done in the «SYMB»execute«ENDSYMB» method. 
            The «SYMB»SimplexWritableVariable«ENDSYMB» is 
            just a utility which, when entry (dimension) index «SYMB»sampledDim«ENDSYMB» is altered 
            in the simplex, 
            the following index (modulo the number of entries) is decrease by the same amount. 
            After picking an index, we use a slice sampler to perform the actual sampling.
          '''
          it += '''
            The instantiation of samplers is automated. The instance variables annotated with 
            «SYMB»@SampledVariable«ENDSYMB» and «SYMB»@ConnectedFactor«ENDSYMB» guide this process. 
          '''
          unorderedList[
            it += '''«SYMB»@SampledVariable«ENDSYMB» is filled with the variable to be sampled. '''
            it += '''Then the factors connected this variables need to be all assigned to «SYMB»@ConnectedFactor«ENDSYMB» 
                        for the sampler to be included in the sampling process. '''
            unorderedList[
              it += '''
                «SYMB»LogScaleFactor«ENDSYMB» is the interface for the factors created by 
                «SYMB»logf«ENDSYMB» and «SYMB»indicator«ENDSYMB» blocks. 
              '''
              it += '''
                «SYMB»Constrained«ENDSYMB» is a factor used to mark variables that require special samplers. 
                            For example, the Dirichlet distribution contains the line «SYMB»realization is Constrained«ENDSYMB» 
                            to ensure standard samplers for real variables are avoided in the context of a simplex.
              '''
            ]
            it += '''
              The optional method «SYMB»setup«ENDSYMB» performs additional initialization checks if needed. 
              It should return a boolean indicating whether this sampler should be used or not in the current context. 
            '''
          ] 
        ]
      ]
    ]
    
    section("More pointers") [
      it += '''
        Additional tutorial and reference materials to go more in-depth:
      '''
      unorderedList[
        it += '''
          «LINK(BuiltInRandomVariables::page)»Built in random variables«ENDLINK»: building blocks for Blang models.
        '''
        it += '''
          «LINK(BuiltInDistributions::page)»Built in distributions«ENDLINK».
        '''
        it += '''
          «LINK(Syntax::page)»Complete description of Blang's syntax.«ENDLINK»
        '''  
        it += '''
          «LINK(InputOutput::page)»Input and Output«ENDLINK»: how to get data into Blang for conditioning, and samples out.
        '''
        it += '''
          «LINK(InferenceAndRuntime::page)»Inference and runtime«ENDLINK»: how the Blang runtime system performs inference 
          based on Blang models. 
        ''' 
        it += '''
          «LINK(CreatingTypes::page)»Custom types«ENDLINK»: more details on creating your own types.
        '''
        it += '''
          «LINK(Testing::page)»Testing«ENDLINK»: tests used to check the correctness of Blang SDK as well as your 
          distributions, samplers and types.
        '''
      ]
    ]

  ]
  
  // TODO: have those ran automatically as test cases
  
  val static String arguments = '''
    --model.rate 1.0 \
    --model.y 1.2 \
    --model.z NA
  '''
  
  val static String result = '''
    Preprocessing started
    1 samplers constructed with following prototypes:
    RealScalar sampled via: [RealSliceSampler]
    Sampling started
    Normalization constant estimate: -1.8657991502743467
    Preprocessing time: 77.99 ms
    Sampling time: 2.511 s
    executionMilliseconds : 2593
    outputFolder : /Users/bouchard/w/blangSDK/results/all/2017-12-15-14-45-13-qFhVg0M8.exec
  '''
  
  // TODO: data file from resource or o.w.
  
  val static String dataFileTop = '''
    "","LV.Type","numberOfLaunches","numberOfFailures"
    "1","Aerobee",1,0
    "2","Angara A5",1,0
    "3","Antares 110",2,0
    "4","Antares 120",2,0
    "5","Antares 130",1,1
    "6","Antares 230",1,0
    "7","Ariane 1",11,2
    "8","Ariane 2",6,1
    "9","Ariane 3",11,1
    "10","Ariane 40",7,0
  '''
  
  val static String hierarchicalModelOpts = '''
    --model.data failure_counts.csv \
    --model.rocketTypes.name LV.Type
  '''
  
}
package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.xdoc.components.Code.Language
import blang.xdoc.components.LinkTarget

class Home {
  
  public val static Document page = new Document("Home") [
    
    isIndex = true
    
    code(Language.blang, firstExample)
    
    it += '''The above example illustrates several aspects of Blang:''' 
    
    unorderedList[
      it += '''
        Blang goes beyond simple real and integer valued random variables. Here we have a type of 
        phylogenetic tree, «SYMB»UnrootedTree«ENDSYMB». 
        Bayesian inference over combinatorial spaces is important and currently neglected. 
        So Blang uses an open type system and assists you in creating complex random types and correct sampling 
        algorithms for these types. 
      '''
      it += '''
        All the distributions shown, e.g. «SYMB»Exponential«ENDSYMB», «SYMB»NonClockTreePrior«ENDSYMB», etc, 
        in particular, those in the SDK, are themselves written in Blang. 
        This is important for extensibility and, crucially, for teaching. When using the Blang IDE, students 
        can command-click on a distribution to jump to its definition in the language they are familiar with. 
      '''
      it += '''
        The parameters of the distributions can themselves be distributions, e.g. «SYMB»NonClockTreePrior«ENDSYMB» taking in a 
        «SYMB»Gamma«ENDSYMB» distribution as argument. This is useful to create rich probability models such as Bayesian 
        non-parametric priors.
      '''
      it += '''
        As hinted by the keyword «SYMB»package«ENDSYMB», you can use other people's models, and package yours easily 
        (and in a versioned fashion). This is useful to disseminate your work and critical to create reproducible analyses. 
        Details such as dependency resolution are taken care of automatically. 
      '''
    ]
    
    it += '''
      If you have one more minute to spare, let us see what happen when we run this model (if you want to try at home, 
      all you need to run this is «LINK("https://openjdk.java.net/")»Open or Oracle SDK 8 SDK«ENDLINK» 
      and git installed):
    '''
    
    code(Language.text, runningByShell)
    
    unorderedList[
      it += '''
        We inferred a distribution over unobserved phylogenetic trees given an observed multiple sequence 
        alignment.
      '''
      it += '''
        The engine used here, «SYMB»SCM«ENDSYMB» (Sequential Change of Measure) is based on state-of-the-art 
        «LINK("https://www.stats.ox.ac.uk/~doucet/delmoral_doucet_jasra_sequentialmontecarlosamplersJRSSB.pdf")»sampling methods«ENDLINK». 
        It uses Jarzynski's method (with annealed distributions created automatically 
        from the model) with a Sequential Monte Carlo algorithm and an adaptive temperature schedule. Other methods 
        include Parallel Tempering, various non-reversible methods, and users can add other inference frameworks as well.
      '''
      it += '''
        The algorithm trivially parallelize to a large number of CPUs, here only 8 cores were used. 
        Massive distribution over many nodes is in the pipeline. 
      '''
      it += '''
        The method provides an estimate of the evidence, here «SYMB»-1216.56«ENDSYMB», which is critical for model 
        selection and lacking in many 
        existing tools. Running again the method with twice as many particles, we get «SYMB»-1216.00«ENDSYMB», 
        suggesting the estimate is getting close to the true value. In contrast, variational methods will 
        typically only give a bound on the true evidence.
      '''
      it += '''
        The resulting samples are easy to use: tidy csv's in a unique execution folder created for each run. 
        You can integrate Blang in your data analysis pipeline seamlessly. 
      '''
      it += '''
        The command line arguments are automatically inferred from the random variables declared in the model and 
        the constructors of the corresponding types (with a bit of help of some annotations). 
      '''
      it += '''
        Blang is built using Xtext, a powerful framework for designing programming languages. 
        Thanks to this infrastructure, Blang incorporates a feature set comparable to many modern full fledge 
        multi-paradigm language: functional, generic and object programming, static typing, just-in-time compilation, 
        garbage collection, IDE support leverage static types and including debugging, etc. 
      '''
      it += '''
        Blang runs on the JVM, so it is reasonably fast (typically within a small factor to any contender) 
        without resorting to rewriting inner loops into low-level, error prone languages. 
        You can also call any Java or Xtend code, and there is a good interoperability potential with the 
        industrial data science stack such as Hadoop, Spark and DL4J. 
      '''
      it += '''
        Blang is free and open source (permissive Berkeley License for both the «LINK("https://github.com/UBC-Stat-ML/blangSDK")»SDK«ENDLINK» and the 
        «LINK("https://github.com/UBC-Stat-ML/blangDSL")»language infrastructure«ENDLINK»).
      '''
    ]
    downloadButton[
      label = "Get started"
      file = downloadLink
      redirect = GettingStarted::page 
    ]
    
    
    it += '''
      <br/>
      <br/>
      <img src="ide.jpg" class="center-block" style="max-width: 600px;" />
    '''
    
  ]
  
  // TODO: test case that link address ok
  
  val static public LinkTarget downloadLink = LinkTarget::url("downloads/blang-mac-latest.zip")
  
  // TODO: have those ran automatically as test cases
  
  def static String firstExample() { 
    '''
      package demo
      import conifer.*
      import static conifer.Utils.*
      
      model Example {
        random RealVar shape ?: latentReal, rate ?: latentReal
        random SequenceAlignment observations
        random UnrootedTree tree ?: unrootedTree(observations.observedTreeNodes)
        param EvolutionaryModel evoModel ?: kimura(observations.nSites)
        
        laws {
          shape ~ Exponential(1.0)
          rate ~ Exponential(1.0)
          tree | shape, rate ~ NonClockTreePrior(Gamma.distribution(shape, rate))
          observations | tree, evoModel ~ UnrootedTreeLikelihood(tree, evoModel) 
        }
      }
    '''
  }
  
  def static String runningByShell() {
    '''
      > git clone https://github.com/UBC-Stat-ML/blangExample.git
      [cloning]
      
      > ./gradlew installDist
      [downloading dependencies and compiling]
      
      > ./build/install/example/bin/example \
        --model.observations.file data/primates.fasta \
        --model.observations.encoding DNA \
        --engine SCM \
        --engine.nThreads Max \
        --excludeFromOutput observations 
      
      Preprocess {
        4 samplers constructed with following prototypes:
          RealScalar sampled via: [RealSliceSampler]
          UnrootedTree sampled via: [SingleNNI, SingleBranchScaling]
      } [ endingBlock=Preprocess blockTime=194.1ms blockNErrors=0 ]
      Inference {
        [...]
        Log normalization constant estimate: -1216.5646966156646
        Final rejuvenation started
      } [ endingBlock=Inference blockTime=2.763min blockNErrors=0 ]
      Postprocess {
        No post-processing requested. Use '--postProcessor DefaultPostProcessor' or run after the fact using 'postprocess --help'
      } [ endingBlock=Postprocess blockTime=1.446ms blockNErrors=0 ]
      executionMilliseconds : 166022
      outputFolder : /Users/bouchard/w/blangExample/results/all/2020-09-24-22-06-26-pAotxNaQ.exec
    '''
  }
  
}
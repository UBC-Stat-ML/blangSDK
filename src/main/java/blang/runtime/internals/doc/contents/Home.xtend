package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document

import blang.runtime.internals.doc.components.Code.Language

import static extension blang.runtime.internals.doc.components.DocElement.*
import blang.runtime.internals.doc.components.LinkTarget

class Home {
  
  public val static Document page = Document.create("Home") [
    
    code(Language.blang, firstExample)
    
    it += '''The above example illustrates several aspects of Blang:''' 
    
    unorderedList[
      it += '''
        Blang can go beyond simple real and integer valued random variables, for example we have a type of 
        phylogenetic tree here, «SYMB»UnrootedTree«ENDSYMB». 
        We believe Bayesian inference over combinatorial spaces is important in practice and currently neglected. 
        So Blang uses an open type system and assists you in creating complex random types and correct sampling 
        algorithms for these types. 
      '''
      it += '''
        All the distributions shown, e.g. «SYMB»Exponential«ENDSYMB», «SYMB»NonClockTreePrior«ENDSYMB», etc, 
        including those in the SDK, are themselves written in Blang.
        This is important for extensibility and, crucially, for teaching. When using the Blang IDE, the student 
        can command click on a distribution to see its definition in the language they are familiar with. 
      '''
      it += '''
        The parameters of the distributions can themselves be distributions, e.g. «SYMB»NonClockTreePrior«ENDSYMB» taking in a 
        «SYMB»Gamma«ENDSYMB» distribution as argument. This is useful to create rich probability models such as Bayesian 
        non-parametric priors.
      '''
      it += '''
        As hinted by the keyword «SYMB»package«ENDSYMB», you can use other people's models, and package yours easily 
        (and in a versioned fashion). This is useful to dissiminate your work and critical to create reproducible analyses. 
        Details such as dependency resolution are taken care of automatically. 
      '''
    ]
    
    it += '''
      If you have one more minute to spare, let us see what happen when we run this model (if you want to try at home, 
      all you need to run this is «LINK("http://www.oracle.com/technetwork/java/javase/downloads/jre8-downloads-2133155.html")»Java 8«ENDLINK» 
      and git intalled):
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
        The algorithm trivially parallelize to hundreds of CPUs, here only 8 cores were used.
      '''
      it += '''
        The method provides an estimate of the evidence, here «SYMB»-1227.75«ENDSYMB», which is critical for model 
        selection and lacking in many 
        existing tools. Running again the method with twice as many particles, we get «SYMB»-1227.15«ENDSYMB», 
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
      it += '''Blang is free and open source (permissive Berkeley License).'''
    ]
    downloadButton[
      label = "Get started"
      file = LinkTarget::url("test.zip")
      redirect = GettingStarted::page
    ]
    // - have animated gif with Desktop IDE, Web IDE, Command line and links
  ]
  
  def static String firstExample() { 
    '''
      package demo
      import conifer.*
      import static conifer.Utils.*
      
      model Example {
        random RealVar shape ?: realVar, rate ?: realVar
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
      > git clone git@github.com:UBC-Stat-ML/blangExample.git
      [cloning]
      
      > ./gradlew installDist
      [downloading dependencies and compiling]
      
      > ./build/install/example/bin/example \
        --model.observations.file primates.fasta \
        --model.observations.encoding DNA \
        --engine SCM \
        --engine.nThreads MAX 
      
      Preprocessing started
      RealScalar sampled via: [RealSliceSampler]
      UnrootedTree sampled via: [SingleNNI, SingleBranchScaling]
      Sampling started
      Normalization constant estimate: -1227.7537992263346
      Preprocessing time: 154.2 ms
      Sampling time: 1.901 min
      outputFolder : /Users/bouchard/w/conifer/results/all/2017-11-30-19-43-22-C7VMR7rK.exec
    '''
  }
  
}
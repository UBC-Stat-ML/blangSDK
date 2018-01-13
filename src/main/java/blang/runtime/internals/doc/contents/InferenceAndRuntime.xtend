package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import blang.mcmc.SimplexSampler

import static extension blang.runtime.internals.doc.DocElementExtensions.code
import blang.types.DenseSimplex
import blang.runtime.internals.doc.components.Code.Language

class InferenceAndRuntime {
  
  public val static Document page = new Document("Inference and runtime") [
    category = Categories::reference
    section("Inference and runtime: overview") [
      it += '''
        The runtime system is responsible for loading data and performing Bayesian inference 
        based on that data. We seek to make inference correct, general, automated and efficient 
        (prioritized in that order): 
      '''
      orderedList[
        it += '''
          «EMPH»correctness«ENDEMPH» is approached using a comprehensive suite of tests«ENDLINK» based on 
          Monte Carlo theory combined with software engineering methodology;
        '''
        it += '''
          «EMPH»generality«ENDEMPH» is provided with an open type system and facilities to 
          quickly develop and test sampling algorithms for new types;
        '''
        it += '''
          «EMPH»automation«ENDEMPH» is based on inference algorithms that remove the need for 
          careful initialization of models as well as an injection framework to ease data loading 
          and conditioning;
        '''
        it += '''
          «EMPH»efficiency«ENDEMPH» is addressed by built-in support for correct and reproducible 
          parallel execution, automatic detection of sparsity structure, and innovative sampling 
          engines based on non-reversible Monte Carlo methods. 
        '''
      ]
      it += '''
        The tools for «LINK(Testing::page)»testing«ENDLINK» and 
        «LINK(CreatingTypes::page)»creating new types«ENDLINK» are described in their own pages. 
        We describe here the inner workings of Blang's automatic, efficient inference machinery in 
        this page. From the user's point of view, this page can be skipped at first reading and is 
        more targeted at developers and Monte Carlo researchers. 
      '''
    ]
    
    section("Detection of sparsity patterns") [
      
      it += '''
        In this section, we describe how a Blang model, say «MATH»m«ENDMATH» (i.e. the contents of «SYMB».bl«ENDSYMB» 
        file) gets transformed into an efficient representation aware of «MATH»m«ENDMATH»'s sparsity patterns. 
        This final efficient form is an instance of «SYMB»blang.runtime.SampledModel«ENDSYMB», a mutable object 
        keeping track of the state space and offering methods to: 
      '''
      unorderedList[
        it += '''change the temperature of the model, going from prior to posterior (see next section for details);'''
        it += '''apply a transition kernel in place targeting the current temperature;'''
        it += '''perform forward simulation in place;'''
        it += '''get the joint log density of the current configuration;'''
        it += '''duplicating the state via a deep cloning library.'''
      ]
      it += '''
        A quick note on mutability: the practice of modifying objects in place is typically avoided as it 
        makes testing more involved. However it is required here for high-performance sampling and our testing 
        framework helps ensure correctness is maintained.'''
      
      section("Preprocessing") [
      
        it += '''
          The process of translation of a Blang model into a SampledModel starts with the instantiation of 
          the model variables (which includes executing the default initialization 
          blocks of unspecified variables).
  
          After his is done, the Blang runtime constructs a list «MATH»l«ENDMATH» of factors. 
          This is done recursively as follows:
        '''
        unorderedList[
          it += '''
            For each «SYMB»blang.core.Model«ENDSYMB» encountered (starting at «MATH»m«ENDMATH»), 
            execute the code generated by the 
            laws block of the model. 
            The generated code is in a method called «SYMB»components«ENDSYMB», which returns a collection «MATH»c«ENDMATH» of 
            «SYMB»blang.core.ModelComponent«ENDSYMB»s, an interface encompassing  
            «SYMB»blang.core.Model«ENDSYMB» and «SYMB»blang.core.Factor«ENDSYMB».
            
            For each item «MATH»i«ENDMATH» in this collection «MATH»c«ENDMATH»,
          '''
          unorderedList[
            it += '''
              If «MATH»i«ENDMATH» is of type «SYMB»blang.core.Factor«ENDSYMB», add «MATH»i«ENDMATH» 
              to «MATH»l«ENDMATH». 
              This case usually corresponds to the code generated by 
              a «SYMB»logf(...) { ... }«ENDSYMB» or «SYMB»indicator(...)  { ... }«ENDSYMB» block, 
              in both cases the generated factor will be a 
              subtype of the subinterface «SYMB»blang.core.LogScaleFactor«ENDSYMB». 
              It may also occur by a statement of the form «SYMB»variable is Constrained«ENDSYMB», 
              in which case the instantiated object is «SYMB»blang.core.Constrained«ENDSYMB».
            '''
            it += '''
              If «MATH»i«ENDMATH» is of type «SYMB»blang.core.Model«ENDSYMB», the present procedure 
              is invoked to obtained a list «MATH»l'«ENDMATH», the elements of which are all added 
              to the present list «MATH»l«ENDMATH».
            '''
          ]
        ]
        it += '''
          The next phase of initialization consists in building from the 
          instantiated Blang model an «EMPH»accessibility graph«ENDEMPH»,  
          defined as follows. Vertices are taken as the transitive closure of objects (starting at the root model) 
          and of the constituents of these objects. 
          Constituents are fields in the case of objects and integer indices in the 
          case of arrays. 
          Exploration of a field can be skipped in the construction of the accessibility graph 
          using the annotation «SYMB»@SkipDependency«ENDSYMB».
          Constitutents can also be customized, as we describe later, for example to index entries of matrices. 
          The (directed) edges of the accessibility graph connect  
          objects to their constituents, and constituents to the object they resolve 
          to, if any. For example, a field might resolve to another object, creating an edge to that object, 
          or to null or a primitive in 
          which case no edge is created. We say that an object «MATH»o_2«ENDMATH» is «EMPH»accessible«ENDEMPH» 
          from «MATH»o_1«ENDMATH» if there is a directed path from «MATH»o_1«ENDMATH» to «MATH»o_2«ENDMATH».
        '''
      ]
      
      section("Identification of the latent variables") [
      
        it += '''
          The latent variables are extracted from the vertex set of the accessibility graph as the intersection 
          of:
        ''' 
        unorderedList[
          it += '''
            objects of a type annotated with «SYMB»@Samplers«ENDSYMB» (more precisely, object where the class 
            itself, a superclass, or 
            an implemented interface has the annotation «SYMB»@Samplers«ENDSYMB»); 
          '''
          it += '''
            objects that are «EMPH»mutable«ENDEMPH», or have an accessible mutable children. 
            Mutability is defined as follows.
          '''
          unorderedList[          
            it += '''
              By default, 
              mutability corresponds to accessibility of non-final fields (in Java, fields not marked with the 
              «SYMB»final«ENDSYMB» keyword, in Xtend, fields marked with «SYMB»var«ENDSYMB») or arrays. 
              This behaviour can be overwritten with the annotation «SYMB»@Immutable«ENDSYMB»;
            '''
            it += '''
              To get finer control on mutability, a designated «SYMB»Observations«ENDSYMB» object can be used 
              to mark individual nodes as observed. For example, this can be used to mark an individual entry 
              of a matrix as observed, using «SYMB»observationsObject.markAsObserved(matrix.getRealVar(i, j))«ENDSYMB». 
              An instance of the Observations object is typically obtained via injection, as described in the 
              «LINK(InputOutput::page)»input output page«ENDLINK». When a node is marked as observed, so is all 
              of its accessible children.
            '''
          ]
        ]
      ]
        
      section("Sparsity") [
        it += '''
          Given an accessibility graph, we are now able to efficiently answer the following questions: given a latent 
          variable «MATH»v«ENDMATH» and a factor «MATH»f«ENDMATH», determine if the application of a sampling operator on 
          «MATH»v«ENDMATH» can change the numerical value of the factor «MATH»f«ENDMATH». More precisely, to determine the 
          answer to this question, we 
          determine if  «MATH»v«ENDMATH» and «MATH»f«ENDMATH» are «EMPH»co-accessible«ENDEMPH». Two objects «MATH»o_1«ENDMATH» 
          and «MATH»o_2«ENDMATH» are co-accessible if there is a mutable object «MATH»o_3«ENDMATH» such that «MATH»o_3«ENDMATH» is 
          accessible from both «MATH»o_1«ENDMATH» and «MATH»o_2«ENDMATH».
          
          The total cost of the algorithm we use for finding, for each latent variable, all the co-accessible factors is proportional 
          to the sum over the factors «MATH»f_i«ENDMATH» of the number of nodes accessible from «MATH»f_i«ENDMATH». 
          The cost of this pre-processing is therefore expected to be negligible compared to the cost of sampling. 
          See «SYMB»blang.runtime.internals.objectgraph.GraphAnalysis«ENDSYMB» for details. 
        '''
      ]
    ]
    
    section("Matching transition kernels") [
      
      it += '''
        After identification of sparsity patterns, samplers are automatically matched to latent variables. 
        To demonstrate how it is done, let us look for example at the declaration 
        of the type «SYMB»Simplex«ENDSYMB»:
      '''

      code(DenseSimplex) [
        val lines = split("\\R")
        val declLine = lines.findFirst[matches(".*[@]Samplers.*")]
        val declIndex = lines.indexOf(declLine)
        "...\n" + lines.subList(declIndex, declIndex + 2).join("\n") + "\n..."
      ]
      
      it += '''
        Here the annotation «SYMB»Samplers«ENDSYMB» provides a comma separated list of sampling algorithms. Here is the 
        specific sampler here:
      '''
      
      code(SimplexSampler)
      
      it += '''
        The sampler should have exactly one field annotated with «SYMB»@SampledVariable«ENDSYMB», it will be automatically 
        populated with the variable being sampled. 
        
        Then the sampler can declare one or several factors or lists of factors that are supported. These will also be 
        populated automatically by using the graph analysis machinery described above. For example, the list 
        «SYMB»numericFactors«ENDSYMB» in the above example will be populated with all the «SYMB»LogScaleFactor«ENDSYMB»s that 
        are co-accessible with the variable «SYMB»simplex«ENDSYMB». 
        
        Instantiation of the sampler will only be considered if all the 
        co-accessible factors can be matched to some field with the «SYMB»@ConnectedFactor«ENDSYMB» annotation (either directly, 
        or into a list specifying the type of factor via its generic type parameter).
        This mechanism can be used to disable default samplers. For example, going back to our simplex variable example, 
        naive methods such as 
        one-node Metropolis-Hastings should be avoided. To do so, we use a «SYMB»Constrained«ENDSYMB» variable (see for 
        example in Dirichlet.bl), so that the slice sampler is not instantiated (it does not declare any annotated 
        field of type Constrained).
      '''
    ]
    
    section("Construction of a sequence of measures and forward generation") [
      it += '''
        For many posterior inference methods, it is useful to have a sequence of measures parameterized by an annealing 
        parameter «MATH»t \in [0, 1]«ENDMATH» such that «MATH»t = 0«ENDMATH» corresponds to an easy to sample distribution 
        (e.g. the prior), and «MATH»t = 1«ENDMATH» corresponds to the distribution of interest. For example, this is 
        necessary to apply parallel tempering or sequential change of measure methods. 

        Having a sequence of distributions also helps alleviate the initialization problems found in purely MCMC methods, 
        which require the sampler to start at a point of positive density. With Blang, we use the intermediate distributions 
        to soften the support restrictions, returning when going out of support a small density going to zero as the temperature 
        approaches one. This does not affect the asymptotic guarantees of our inference method as the restrictions 
        are enforced at «MATH»t = 1«ENDMATH». 
        
        One challenge when constructing the sequence of measures is that we have to guarantee that all intermediate measures 
        have a finite normalization constant, otherwise the inference algorithms may silently fail, i.e. the Monte Carlo 
        average may diverge or converge to incorrect values. We use the following strategy to avoid this problem.  
        First, let us view the Blang model as a directed graphical model (we describe in more detail how this is done below).
        In this representation, the factors correspond to nodes in the graph. We split the factors into two groups according to 
        whether the node is observed or unobserved node. Let us denote the product of the factors in each of the two groups by 
        «MATH»\ell(x) = \prod_{i\in I} \ell_i(x)«ENDMATH» and «MATH»p(x) = \prod_{j\in J} p_j(x)«ENDMATH» respectively (here 
        «MATH»x«ENDMATH» encompasses all latent variables). The target posterior distribution satisfies 
        «MATH»\pi(x) \propto p(x)\ell(x)«ENDMATH». In simple cases, «MATH»\ell(x)«ENDMATH» corresponds to the 
        likelihood and «MATH»p(x)«ENDMATH», to the prior; however we avoid the terminology since the formal definition 
        given below generalizes to complex models where there is not necessarily a clear cut prior and likelihood. We do have
        that «MATH»\int p(x) \text{d} x = 1«ENDMATH» in general though. Assuming the problem is well posed, the posterior 
        is also normalizable, «MATH»\int p(x) \ell(x) \text{d} x < \infty«ENDMATH», and moreover the same is true for subsets 
        of observations, i.e. for «MATH»K \subset I«ENDMATH», «MATH»\int p(x) \prod_{i\in K} \ell_i(x) \text{d} x < \infty«ENDMATH».
        
        Given that notation, the sequence of intermediate measures we use is given by 
        «EQN»\pi_t(x) = p(x) \prod_{i\in I}[(\ell_i(x))^t + I(\ell_i(x) = 0) \epsilon_t],«ENDEQN»where «MATH»\epsilon_t \le 1«ENDMATH» 
        is a decreasing sequence such «MATH»\epsilon_1 = 0«ENDMATH» and «MATH»I(\cdot)«ENDMATH» denotes an indicator. 
        Concretely, we use «MATH»\epsilon_t = \exp(-t 1\text{e}100) I(t < 1)«ENDMATH».
        
      '''
      section("Normalizability") [
        it += '''
          Measures in this sequences are guaranteed to have finite normalization since:
          «EQN»
          \int \pi_t(x) \text{d} x  &= \int p(x) \prod_{i\in I}[ (\ell_i(x))^t + I(\ell_i(x) = 0) \epsilon_t ] \text{d} x\\
            &= \sum_{K: K \subset I} \epsilon_t^{|I|-|K|} \int p(x) (\prod_{i \in K}\ell_i(x))^t \text{d} x \\
            &= \sum_{K: K \subset I} \epsilon_t^{|I|-|K|} \int p(x) (\prod_{i \in K}\ell_i(x))^t [I(\prod_{i \in K}\ell_i(x) \ge 1) + I(\prod_{i \in K}\ell_i(x) < 1)] \text{d} x \\
            &\le \sum_{K: K \subset I} \epsilon_t^{|I|-|K|} [\int p(x) \prod_{i \in K}\ell_i(x) \text{d} x + \int p(x) \text{d} x] \\
            &< \infty.
          «ENDEQN»
        '''
      ]
      
      section("Discovery of measure sequences: some details") [
        it += '''
          The process by which factors are seggregated between the "prior" set «MATH»\{p_j : j\in J\}«ENDMATH» and the 
          "likelihood" set «MATH»\{\ell_i : i\in I\}«ENDMATH» proceeds recursively from the root model:
        '''
        unorderedList[
          it += '''If the model has a «SYMB»generate«ENDSYMB» block:'''
          unorderedList[
            it += '''
              If all the model's «SYMB»random«ENDSYMB» variables are observed (not latent), 
              put all the numerical factors defined by this model in the set «MATH»\{\ell_i : i\in I\}«ENDMATH».
            '''
            it += '''
              If all the model's «SYMB»random«ENDSYMB» variables are latent, put all the 
              numerical factors defined by this model in the set «MATH»\{p_j : j\in J\}«ENDMATH».
            '''
            it += '''
              If the current model's «SYMB»random«ENDSYMB» variables are partially observed, 
              throw an exception.
            '''
          ]
          it += '''If the model does not have a «SYMB»generate«ENDSYMB» block'''
          unorderedList[
            it += '''
              Recurse over all components of the model. Assume they are all themselves 
              models (i.e. if a model does not have «SYMB»generate«ENDSYMB» block, all 
              items in the «SYMB»laws«ENDSYMB» block should be based on the «SYMB»... | ... ~ ...«ENDSYMB»
              construct rather than the «SYMB»logf«ENDSYMB» and «SYMB»indicator«ENDSYMB» ones.
            '''
          ]
        ]
        it += '''
          We point out that this decomposition is not possible for all models. In such cases, 
          it is often possible to rewrite the models to follow the rules outlined above. If not, 
          the user can also back off to inference methods that do not require a sequence of measures. 
          This can be done with the command line arguments (also setting the inference engine to 
          Parallel Tempering with a single chain (PT):
        '''
        code(Language.text, 
          '''--checkIsDAG false --engine.usePriorSamples false --skipForwardSamplerConstruction true --engine PT --engine.ladder.nChains 1''')
      ]
    ]
    
    section("Inference algorithms") [
      it += '''
        Several inference algorithms are available built-in. 
        They can be configured by providing various arguments to the main application. To get a full list, 
        you can always use the switch «SYMB»--help«ENDSYMB». Grep «SYMB»engine«ENDSYMB» to find the subset 
        related to inference algorithms. 
        The selection is controlled with the 
        switch «SYMB»--engine«ENDSYMB»:
      '''
      unorderedList[
        it += '''
          «SYMB»SCM«ENDSYMB»: Sequential Change of Measure. This pushes a population of particles from 
          the distribution «MATH»\pi_0«ENDMATH» into «MATH»\pi = \pi_1«ENDMATH». In summary:
        '''
        unorderedList[
          it += '''
            First, the forward simulation machinery is used to get 
            exact samples from «MATH»\pi_0«ENDMATH». Several «EMPH»particles«ENDEMPH» are hence created. 
            The number of particles is controlled with «SYMB»--engine.nParticles«ENDSYMB» and controls 
            the quality of the approximation. 
          '''
          it += '''
            Then annealing parameter («MATH»t«ENDMATH» indexing «MATH»\pi_t«ENDMATH») is then increased 
            sequentially from zero to one. 
            At each iteration, each particle is perturbed by a transition kernel invariant with respect
            to the next annealed target and reweighted to take into account the annealing parameter increase. 
            The amount of increase at each 
            iteration is controlled by «SYMB»--engine.temperatureSchedule«ENDSYMB», and the default value, 
            «SYMB»AdaptiveTemperatureSchedule«ENDSYMB», is based on an adaptative strategy, see 
            «LINK("https://arxiv.org/abs/1303.3123")»Zhou, Johansen and Aston (2013)«ENDLINK». 
          '''
          it += '''
            When the relative Effective Sample Size (ESS) falls under a threshold 
            (specified by the command line argument «SYMB»--engine.resamplingESSThreshold«ENDSYMB»), resampling is performed. 
            The «LINK("https://arxiv.org/abs/physics/9803008")»Annealed Importance Sampling«ENDLINK» algorithm 
            can be recovered as special case by 
            setting «SYMB»--engine.resamplingESSThreshold 0.0«ENDSYMB». 
            
          '''
          it += '''
            After obtaining particles approximately distributed according to «MATH»\pi_1 = \pi«ENDMATH» the quality of the 
            approximation can be optionally increased by performing rejuvenation steps on each particles, i.e. scans 
            where all transition kernels targeting «MATH»\pi«ENDMATH» are applied in a random order. The number of 
            such scans is set by «SYMB»--engine.nFinalRejuvenations«ENDSYMB». Set to zero disable.
          '''
        ]
        it += '''
          «SYMB»PT«ENDSYMB»: Parallel Tempering. This creates parallel MCMC chains, each targeting different annealing 
          parameters. Documentation under construction (and some arugments might change a bit).
        '''
        it += '''
          «SYMB»Forward«ENDSYMB»: Use the forward simulation machinery for the subset of the states that are not 
          observed.
        '''
        it += '''
          «SYMB»Exact«ENDSYMB»: For models that are fully discrete, this enumerates all the configurations. The current
          algorithm 
          does not attempt to exploit conditional independence assumptions and has exponential computational complexity. 
          It is still useful for debugging and pedagogy. 
        '''
      ]
    ]
    
    section("Advanced graph analysis") [
      it += '''
        The construction of the object graph (used for determining sparsity patterns) can be customized. 
        The main use case for such customization is to construct views into larger objects, e.g. 
        slices of matrices. 
        
        How the object graph is explored is controlled in «SYMB»blang.runtime.internals.objectgraph.ExplorationRules«ENDSYMB». 
        To customize, one would change the list of rules in the static field «SYMB»defaultExplorationRules«ENDSYMB» via 
        static initialization.
      '''
    ]
  ]
}
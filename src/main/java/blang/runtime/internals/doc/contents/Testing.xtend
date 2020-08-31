package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.Categories
import blang.xdoc.components.Code.Language
import blang.xdoc.components.Document
import blang.validation.UnbiasnessTest

import static extension blang.xdoc.DocElementExtensions.*

class Testing {
  
  public val static Document page = new Document("Testing Blang models") [
    
    category = Categories::reference
    
    section("Testing correctness: overview") [
      
      it += '''
        There is considerable emphasis in the MCMC and SMC literatures on «EMPH»efficiency«ENDEMPH» (in the computational sense 
        of efficiency), 
        but much less on «EMPH»correctness«ENDEMPH». Here we define correctness as follows: an MCMC procedure producing samples 
        «MATH»X_1, X_2, \dots«ENDMATH» is «EMPH»correct«ENDEMPH» if ergodic averages based any integrable functions 
        «MATH»f«ENDMATH» admit a law of large number converging to the posterior expectation of the function under the target posterior 
        distribution «MATH»\pi«ENDMATH», i.e.
        
        «EQN»\frac{1}{N} \sum_{i=1}^N f(X_i) \to \int f(x) \pi(x) \text{d}x \text{ a.s., } N\to\infty.«ENDEQN»
        
        For SMC-based algorithm, we use a similar definition where instead the number of particles is increased to infinity. 
        
        Correctness can fail for two main reasons: some mathematical derivations used to construct the MCMC or SMC algorithm are incorrect, or, 
        the software implementation is buggy. The tests we describe here can detect both kinds of problems.
        
        Correctness has nothing to do with what the literature vaguely calls "convergence diagnostic". 
        Whether a LLN holds or not does not depend on "burn-in", having low autocorrelation, etc.
        
        In full generality, testing if a deterministic sequence converges to a certain limit is not possible. 
        On top of that, the sequence we have here is composed of random variables, and moreover these random 
        variables are relatively expensive to simulate in problems of practical interest. 
        Hence our definition of correctness appears hopelessly difficult to check. 
        
        Surprisingly, there exists a set of  effective tools to check MCMC and SMC correctness. 
        Some of these tools are in the literature but not emphasized. We compile and improve them in this document, and describe 
        their implementation in Blang.
        
        Analysis of MCMC and SMC correctness is a great example of an area where fairly theoretical concepts can have a 
        large impact to a practical problem. Crucially, as we show here, MC theory will allow us to derive useful tests that are 
        not based on asymptotics and that have exact, easy to compute false positive probabilities. 
        Moreover, in some cases, we can even get non-probabilistic tests, i.e. with zero false positive «EMPH»and«ENDEMPH» zero 
        false negative probabilities. In other cases, tests do not have formal guarantees to find all bugs, but in practice they 
        are useful to identify common ones.
      '''
    ]
    
    section("Testing strategies") [
    
      section("Exhaustive tests") [
        it += '''
          We provide a non-standard replacement implementation of 
          «LINK("https://github.com/alexandrebouchard/bayonet/blob/master/src/main/java/bayonet/distributions/Random.java")»bayonet.distributions.Random«ENDLINK» 
          which can be used to enumerates all the probability traces used by an arbitrary discrete random process.
          In particular, many inference engines' code manipulate models through interfaces that are agnostic to the model being 
          continuous or discrete, so we can achieve code coverage of the inference engines using discrete models.  
          See «LINK("https://github.com/alexandrebouchard/bayonet/blob/master/src/main/java/bayonet/distributions/ExhaustiveDebugRandom.java")»bayonet.distributions.ExhaustiveRandom«ENDLINK».
          
          We use this for example to test the unbiasness of the normalization constant estimate provided by our 
          SMC implementation. 
        '''
        code(UnbiasnessTest)
        it += '''
          This can be called with a small finite model, e.g. 
          «LINK("https://github.com/UBC-Stat-ML/blangSDK/blob/master/src/test/java/blang/TestSMCUnbiasness.xtend")»a short HMM here«ENDLINK», 
          but making it is large enough to achieve «LINK("https://en.wikipedia.org/wiki/Code_coverage")»code coverage«ENDLINK» 
          (Blang and the BlangIDE are compatible with the «LINK("http://www.eclemma.org/")»eclemma«ENDLINK» code coverage tool). 
          
          The output of the test has the form:
        '''
        code(Language.text, '''
          nProgramTraces = 23868
          true normalization constant Z: 0.345
          expected Z estimate over all traces: 0.34500000000000164
        ''')
        it += '''
          Showing that indeed our implementation of SMC is unbiased.

          This can also be used to test numerically that transition probabilities of small state space discrete kernels are indeed invariant 
          with respect to the target (facilities to help automating this will be developed as part of a future release). 
          
          Finally, when a model is fully discrete and all generate{..} blocks have the property that for each realization there is at most
          one execution trace generating it, then we can check that the logf and randomness used in the 
          generate block match by using the arguments:
        '''
        code(Language.text, '''
          --engine Exact --engine.checkLawsGenerateAgreement true
        ''')
      ]
      
      section("Exact invariance test") [
        
        section("Background") [
          it += '''
            The basis of this test is from «LINK("https://www.jstor.org/stable/27590449?seq=1#page_scan_tab_contents")»Geweke (2004)«ENDLINK»
            (this is the Geweke paper on «EMPH»correctness«ENDEMPH» of MCMC, not to be confused with Geweke's «EMPH»convergence diagnostic«ENDEMPH», 
            which as mentioned above, is unrelated), but we modify it in an important way.
            
            Given a Blang model, 
            as in the Geweke paper, we assume it supports two methods for simulating the random variables in the model: one via forward simulation (and since 
            no data is used in this correctness check, it is reasonable to assume all variables can be filled in this fashion; this will be 
            true as long appropriate «SYMB»generate«ENDSYMB» blocks are provided for the constituents); the other, via application of MCMC transition 
            kernels. 
            
            Let «MATH»X«ENDMATH» denote all the variables in the model. Let «MATH»X \sim \pi«ENDMATH» denote the forward simulation process. Let 
            «MATH»X' | X \sim T(\cdot | X)«ENDMATH» denote a combination of kernels including those we want to test for invariance with respect to 
            «MATH»\pi«ENDMATH». Let «MATH»T_i«ENDMATH» denote the individual kernels which are combined into «MATH»T«ENDMATH» via either 
            mixture or composition. Typically, 
            «MATH»T«ENDMATH» is irreducible but not the individual «MATH»T_i«ENDMATH»'s. 
            
            Both our test and Geweke's depend on one or several real-valued test functions «MATH»f«ENDMATH», and on comparing  
            two sets of simulations. However these two sets will be defined differently. 
            
            In Geweke's method, the two sets are:
          '''
          orderedList[
            it += '''
              «EMPH»The marginal-conditional simulator«ENDEMPH»: 
            '''
            unorderedList[
              it += '''
                For «MATH»m \in \{1, 2, \dots, M_1\}«ENDMATH»
              '''
              unorderedList[
                it += '''
                  «MATH»X_m \sim \pi«ENDMATH»
                '''
                it += '''
                  «MATH»F_m = f(X_m)«ENDMATH»
                '''
              ]
            ]
            it += '''
              «EMPH»The successive-conditional simulator«ENDEMPH»: 
            '''
            unorderedList[
              it += '''
                «MATH»X_1 \sim \pi«ENDMATH»
              '''
              it += '''
                «MATH»G_1 = f(X_1)«ENDMATH»
              '''
              it += '''
                For «MATH»m \in \{2, 3, \dots, M_2\}«ENDMATH»
              '''
              unorderedList[
                it += '''
                  «MATH»X_m | X_{m-1} \sim T(\cdot|X_{m-1})«ENDMATH». Here our definition of «MATH»T«ENDMATH» hides some 
                  details in Geweke's method, in particular that one of the «MATH»T_i«ENDMATH»'s re-generate
                  the data given the current parameter values. 
                '''
                it += '''
                  «MATH»G_m = f(X_m)«ENDMATH»
              '''
              ]
            ]
          ]
          it += '''
            Then an approximate test comparing «MATH»\{F_1, F_2, \dots, F_{M_1}\}«ENDMATH» and 
            «MATH»\{G_1, G_2, \dots, G_{M_2}\}«ENDMATH» is derived based on an asymptotic result.
            
            The method has several limitations:
          '''
          unorderedList[
            it += '''
              The validity of the approximate test relies on «MATH»T«ENDMATH» being irreducible, which means 
              that individual kernels «MATH»T_i«ENDMATH» cannot be tested in isolation. Therefore, when the 
              test fails, it can be time consuming to determine the root cause.
            '''
            it += '''
              Whether the «MATH»p«ENDMATH» value exceed a set threshold cannot be known exactly. A leap of faith is 
              needed to assume the asymptotics are sufficiently accurate. Verifying if this is the case can be 
              very difficult in practice. More seriously, the problem is compounded when several such tests 
              need to be combined using a multiple-testing framework. As a consequence Geweke test is not used as 
              an automatic test unit to the best of our knowledge and 
              «LINK("https://hips.seas.harvard.edu/blog/2013/06/10/testing-mcmc-code-part-2-integration-tests/")»practitioners typically recommend visual 
              inspection of P-P plots rather than turning Geweke tests into unit tests«ENDLINK».
            '''
            it += '''
              The validity of the approximate test also relies on a CLT for Markov chains to hold, which in turn 
              typically involves establishing «EMPH»geometric«ENDEMPH» ergodicity. Proving geometric ergodicity 
              is model-dependent and quite involved compared to the weaker conditions required for a law of large numbers.  
            '''
          ]
          it += '''
            We call our alternative the «EMPH»Exact Invariance Test«ENDEMPH» (EIT), and we use it heavily to establish Blang's SDK correctness. 
            EIT has the following properties:
          '''
          unorderedList[
            it += '''
              The test does not rely on irreducibility. This means that individual kernels «MATH»T_i«ENDMATH» can be
              tested individually, which markedly narrows down the code to be reviewed in the event of bug detection.
            '''
            it += '''
              EIT does not rely on asymptotic results. It is an exact test.
            '''
            it += '''
              The test does not rely on geometric ergodicity.
            '''
          ]
          it += '''
            EIT compares the following two sets of samples, «MATH»\{F_1, F_2, \dots, F_{M_1}\}«ENDMATH» and «MATH»\{H_1, H_2, \dots, H_{M_3}\}«ENDMATH»:
          '''
          orderedList[
            it += '''
              Those coming from the marginal-conditional simulator, as described above, «MATH»\{F_1, F_2, \dots, F_{M_1}\}«ENDMATH».
            '''
            it += '''
              «EMPH»The exact invariant simulator«ENDEMPH»: 
            '''
            unorderedList[
              it += '''
                For «MATH»m \in \{1, 3, \dots, M_3\}«ENDMATH»
              '''
              unorderedList[
                it += '''
                  «MATH»X_{1,m} \sim \pi«ENDMATH»
                '''
                it += '''
                  For «MATH»k \in \{2, 3, \dots, K\}«ENDMATH»
                '''
                unorderedList[
                  it += '''
                    «MATH»X_{k,m} | X_{k-1,m} \sim T_i(\cdot|X_{k-1,m})«ENDMATH»
                  '''
                ]
                it += '''
                  «MATH»H_m = f(X_{K,m})«ENDMATH»
                '''
              ]
            ]
          ]
          it += '''
            By construction, for any «MATH»K \ge 1, j \in \{1, \dots, M_1\}, l \in \{1, \dots, M_3\}«ENDMATH», 
            the random variable «MATH»F_j«ENDMATH» is equal 
            in distribution to the random variable «MATH»F_l«ENDMATH» if and only if the kernel «MATH»T_i«ENDMATH» is 
            «MATH»\pi«ENDMATH» invariant. 
            This means that an exact test can be trivially constructed (for example if «MATH»f«ENDMATH» takes on a 
            finite number of values, Fisher's exact test can be used). Alternatively, 
            tests with simple to analyze asymptotics 
            such as the Kolmogorov–Smirnov can be used. Critically, since the «MATH»H_m«ENDMATH»'s are independent, 
            the asymptotics here do not depend on irreducibility or  
            geometric ergodicity, and off-the-shelf iid tests can be used directly. The terminology "Exact" in EIT 
            refers to the random variables being exactly equal in distribution under the null rather than the exactness of the
            frequentist 
            procedure being used to assess if indeed the two sets are equal in distribution. Note that we have here a rare instance  
            where a point null hypothesis is indeed a well grounded approach, even when using very large values for «MATH»M_1, M_3«ENDMATH».
            
            Here «MATH»K \ge 1«ENDMATH» is a parameter controlling the power of test. Exact tests are available for any 
            finite value. 
            
            For completeness, we also review below the Cook et al. test. 
          '''
          /*
            Not great argument b/c loop over i will be there, but outside. Instead in paper can compare to Cook which 
            has same nesting. Also parallelization is still only for EIT.
            
            EIT may seem expensive at first glance because of the double loops over «MATH»M_2«ENDMATH» and 
            «MATH»K«ENDMATH». However the body of the inner loop only involves «MATH»T_i«ENDMATH» rather than «MATH»T«ENDMATH» 
            which can lead to an over cost that is actually lower than Geweke's test in certain models. Moreover, in 
            contrast to Geweke's test, EIT is embarrassingly parallelizable. 
           */
          unorderedList[
            it += '''
              For «MATH»m \in \{1, 3, \dots, M\}«ENDMATH»
            '''
            unorderedList[
              it += '''
                «MATH»\tilde X_{m} \sim \pi«ENDMATH». A subset of the coordinates is held fix 
                for the rest and viewed as synthetic data (i.e. in contrast to Geweke's test, «MATH»T«ENDMATH» does not contain 
                kernels modifying the "data" coordinates of «MATH»X«ENDMATH»).
              '''
              it += '''
                Set «MATH»X_{1,m}«ENDMATH» to be equal to «MATH»\tilde X_{m}«ENDMATH» for observed coordinates, and to 
                some user-specified initialization value otherwise.
              '''
              it += '''
                For «MATH»k \in \{2, 3, \dots, K_2\}«ENDMATH»
              '''
              unorderedList[
                it += '''
                  «MATH»X_{k,m} | X_{k-1,m} \sim T(\cdot|X_{k-1,m})«ENDMATH»
                '''
              ]
              it += '''
                Compute «MATH»Q_m = \frac{1}{K_2} \sum_{k=1}^{K_2} I[f(\tilde X_{m}) < f(X_{k,m})]«ENDMATH»
              '''
            ]
          ]
          it += '''
            Then if the code is correct, the distribution of «MATH»Q_i«ENDMATH» converges to 
            the uniform distribution as «MATH»K_2 \to \infty«ENDMATH», provided the chain is irreducible. 
            Hence this method suffers from the same limitation as Geweke's in terms of not being able to 
            narrow down the error to a single «MATH»T_i«ENDMATH», and being approximate for any finite 
            «MATH»K_2«ENDMATH».
          '''
        ]
        
        section("Implementation of EIT in Blang") [
          
          it += '''
            Prepare the EIS tests by assembling objects of type «SYMB»Instance«ENDSYMB», for which the constructor's first argument 
            is a Blang model, and the following arguments are one or more test functions, playing the role of «MATH»f«ENDMATH» in the 
            previous section. See for example 
            «LINK("https://github.com/UBC-Stat-ML/blangSDK/blob/master/src/test/java/blang/Examples.xtend")»the list of 
            instances used to test Blang's SDK«ENDLINK».
            
            Once the instances are available, you can create an automatic test suite by adding a file under the «SYMB»src/test«ENDSYMB» 
            directory based on the following example:
          '''
          codeFromBlangSDKRepo(Language.xtend, "src/test/java/blang/TestSDKDistributions.xtend")
          
          it += '''
            This takes multiple testing correction under account. The example above also shows a related test, «SYMB»DeterminismTest«ENDSYMB» 
            which ensure reproducibility, i.e. that using the same random seed leads to exactly the same result. 
            
            By virtue of being standard JUnit tests, it is easy to use continuous integration tools such as 
            «LINK("https://travis-ci.org/")»Travis«ENDLINK» so that the tests are ran on a remote server each time a commit is made.
          ''' 
        ]
        
      ]
      
      section("Normalization tests") [
        it += '''
          For individual univariate continuous distributions, this test checks using numerical integration that the normalization is one. 
        '''
        codeFromBlangSDKRepo(Language.java, "src/test/java/blang/TestSDKNormalizations.java")
        it += '''
          Having correct normalization is important when we put priors on the parameters and sample the values of the parameters. In such 
          cases the value of the normalization constant plays an often overlooked role in the correctness of transition kernels.
        '''
      ]
    ]
  ]
  
}
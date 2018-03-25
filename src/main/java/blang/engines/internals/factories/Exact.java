package blang.engines.internals.factories;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.ExhaustiveDebugRandom;
import bayonet.math.NumericalUtils;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.types.ExtensionUtils;

public class Exact implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results;
  
  @Arg(description = "Stop and warn the user if more than this number of random draws is used in a simulation.")
         @DefaultValue("15")
  public int maxDepth = 15;
  
  @Arg(description = "Stop and warn the user if more than this number of traces is used in a simulation.")
          @DefaultValue("100_000")
  public int maxTraces = 100_000;
  
  @Arg(description = "If all generate blocks have the property that for each realization there is at most "
      + "one execution trace generating it, then we can check that the logf and randomness used in the "
      + "generate block match.")
                               @DefaultValue("false")
  public boolean checkLawsGenerateAgreement = false;
  
  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER));
    double logNormalization = logNormalization(model);
    ExhaustiveDebugRandom exhaustive = new ExhaustiveDebugRandom();
    int i = 0;
    while (exhaustive.hasNext())
    {
      model.forwardSample(exhaustive, true);
      
      // check this is not going to take forever
      if (exhaustive.lastDepth() > maxDepth || i > maxTraces)
        throw new RuntimeException("The number of traces or trace depth has been exceeded. "
            + "You should probably switch to an approximate inference engine. "
            + "You can also increase these limits via command line arguments if you are sure. "
            + "currentDepth=" + exhaustive.lastDepth() + " nTraces=" + i);
      
      if (checkLawsGenerateAgreement) 
      {
        double logPrior = model.logDensity(0.0);
        double logPriorRealization = Math.log(exhaustive.lastProbability());
        if (!ExtensionUtils.isClose(logPrior, logPriorRealization))
          throw new RuntimeException("generate(rand){..} block not faithful with its laws{..} block. \n"
              + "Common mistake: forgetting to take the log of the answer in logf() { .. } constructs. \n"
              + "Diverging values: " + logPrior + " vs " + logPriorRealization);
      }
      
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", i++), Pair.of("logProbability", logWeight(model, exhaustive) - logNormalization)); 
    }
  }
  
  public static double logWeight(SampledModel model, ExhaustiveDebugRandom exhaustive)
  {
    double logLikelihood = model.logDensity(1.0) - model.logDensity(0.0);
    /*
     * Prior is not necessarily just model.logDensity(0.0), because the generate code 
     * might potentially have several exec traces generating the same prior realization. 
     */
    double priorRealization = Math.log(exhaustive.lastProbability()); 
    return priorRealization + logLikelihood;
  }
  
  public static double logNormalization(SampledModel model) 
  {
    double logSum = Double.NEGATIVE_INFINITY;
    ExhaustiveDebugRandom exhaustive = new ExhaustiveDebugRandom();
    while (exhaustive.hasNext())
    {
      model.forwardSample(exhaustive, true);
      logSum = NumericalUtils.logAdd(logSum, logWeight(model, exhaustive));
    }
    return logSum;
  }

  SampledModel model;

  @Override
  public void setSampledModel(SampledModel model) 
  {
    this.model = model;
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
  }
}

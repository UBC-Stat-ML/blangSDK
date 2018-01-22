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

public class Exact implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results;
  
  @Arg(description = "Stop and warn the user if more than this number of random draws is used in a simulation.")
         @DefaultValue("15")
  public int maxDepth = 15;
  
  @Arg(description = "Stop and warn the user if more than this number of traces is used in a simulation.")
          @DefaultValue("100_000")
  public int maxTraces = 100_000;
  
  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER));
    ExhaustiveDebugRandom exhaustive = new ExhaustiveDebugRandom();
    int i = 0;
    while (exhaustive.hasNext())
    {
      model.forwardSample(exhaustive, false);
      
      // check this is not going to take forever
      if (exhaustive.lastDepth() > maxDepth || i > maxTraces)
        throw new RuntimeException("The number of traces or trace depth has been exceeded. "
            + "You should probably switch to an approximate inference engine. "
            + "You can also increase these limits via command line arguments if you are sure. "
            + "currentDepth=" + exhaustive.lastDepth() + " nTraces=" + i);
      
      double logWeightFromModel = model.logDensity(1.0);
      
      // checks agreement of generate and law blocks
      double logWeightFromGeneration = Math.log(exhaustive.lastProbability()) + model.logDensity(1.0) - model.logDensity(0.0);
      if (!NumericalUtils.isClose(logWeightFromModel, logWeightFromGeneration, NumericalUtils.THRESHOLD))
        throw new RuntimeException("generate(rand){..} block not faithful with its laws{..} block.");
      
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", i++), Pair.of("logWeight", logWeightFromModel)); 
    }
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
    if (analysis.hasObservations())
      throw new RuntimeException();
  }
}

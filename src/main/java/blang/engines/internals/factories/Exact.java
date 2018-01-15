package blang.engines.internals.factories;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.ExhaustiveDebugRandom;
import bayonet.math.NumericalUtils;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

public class Exact implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results;
  
  SampledModel model;

  @Override
  public void setSampledModel(SampledModel model) 
  {
    this.model = model;
  }

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
      double logWeightFromModel = model.logDensity(1.0);
      double logWeightFromGeneration = Math.log(exhaustive.lastProbability()) + model.logDensity(1.0) - model.logDensity(0.0);
      if (!NumericalUtils.isClose(logWeightFromModel, logWeightFromGeneration, NumericalUtils.THRESHOLD))
        throw new RuntimeException("Generate(rand){..} block not faithful with its laws{..} block.");
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", i++), Pair.of("logWeight", logWeightFromModel)); 
    }
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    if (analysis.hasObservations())
      throw new RuntimeException();
  }
}

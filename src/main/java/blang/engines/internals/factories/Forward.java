package blang.engines.internals.factories;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.Random;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

public class Forward implements PosteriorInferenceEngine
{
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  @Arg   @DefaultValue("1_000")
  public int nSamples = 1_000;
  
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
    for (int i = 0; i < nSamples; i++) 
    {
      model.forwardSample(random, false);
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", i++)); 
    }
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
  }
}

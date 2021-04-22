package blang.engines.internals.factories;


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
    model.forwardSample(random, true);
    model.getSampleWriter(tidySerializer).write();
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
  }
}

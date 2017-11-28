package blang.engines.internals.factories;

import blang.engines.internals.PosteriorInferenceEngine;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

public class None implements PosteriorInferenceEngine 
{

  @Override
  public void setSampledModel(SampledModel model) 
  {
  }

  @Override
  public void performInference() 
  {
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
  }

}

package blang.engines;

import blang.inits.Implementations;
import blang.runtime.SampledModel;
import blang.runtime.objectgraph.GraphAnalysis;

@Implementations({SCM.class, Forward.class})
public interface PosteriorInferenceEngine 
{
  public void setSampledModel(SampledModel model);
  public void performInference();
  public void check(GraphAnalysis analysis);
  
}

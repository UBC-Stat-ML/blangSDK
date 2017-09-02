package blang.engines;

import blang.inits.Implementations;
import blang.runtime.SampledModel;

@Implementations({SMC.class})
public interface PosteriorInferenceEngine 
{
  public void setSampledModel(SampledModel model);
  public void performInference();
  
}

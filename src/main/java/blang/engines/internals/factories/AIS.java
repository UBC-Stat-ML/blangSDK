package blang.engines.internals.factories;

import blang.runtime.SampledModel;

public class AIS extends SCM {
  @Override
  public void setSampledModel(SampledModel model) 
  { 
    resamplingESSThreshold = 0.0;
    super.setSampledModel(model); 
  }
}

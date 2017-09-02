package blang.engines;

import blang.algo.ChangeOfMeasureSMC;
import blang.runtime.ChangeOfMeasureKernel;
import blang.runtime.SampledModel;

public class SMC extends ChangeOfMeasureSMC<SampledModel> implements PosteriorInferenceEngine
{
  @Override
  public void setSampledModel(SampledModel model) 
  { 
    setKernels(new ChangeOfMeasureKernel(model));
  }

  @Override
  public void performInference() 
  {
    getApproximation();
  }
}

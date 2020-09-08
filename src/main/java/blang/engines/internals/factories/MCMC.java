package blang.engines.internals.factories;

import blang.runtime.SampledModel;

public class MCMC extends PT {
  @Override
  public void setSampledModel(SampledModel m) 
  {
    nPassesPerScan = 1;
    nChains = 1;
    usePriorSamples = false;
    initialization = InitType.COPIES;
    super.setSampledModel(m);
  }
  
}

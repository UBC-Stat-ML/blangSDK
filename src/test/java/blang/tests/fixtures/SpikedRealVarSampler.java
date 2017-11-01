package blang.tests.fixtures;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.ConstrainedFactor;
import blang.core.LogScaleFactor;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.IntSliceSampler;
import blang.mcmc.RealSliceSampler;
import blang.mcmc.SampledVariable;
import blang.mcmc.Sampler;
import blang.tests.fixtures.SpikedRealVar; 

import static blang.types.ExtensionUtils.*;

public class SpikedRealVarSampler implements Sampler {
  
  @SampledVariable
  SpikedRealVar variable;
  
  @ConnectedFactor
  ConstrainedFactor constrained;
  
  @ConnectedFactor
  List<LogScaleFactor> numericFactors;
  
  RealSliceSampler sliceSampler;
  IntSliceSampler intSampler;

  @Override
  public void execute(Random rand) 
  {
    if (!asBool(variable.isZero.intValue()))
      sliceSampler.execute(rand);
    intSampler.execute(rand);
  }

  @Override
  public boolean setup() 
  {
    sliceSampler = RealSliceSampler.build(variable.realPart, numericFactors);
    intSampler = IntSliceSampler.build(variable.isZero, numericFactors);
    return true;
  }

}

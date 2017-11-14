package blang.validation.internals.fixtures;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.Constrained;
import blang.core.LogScaleFactor;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.IntSliceSampler;
import blang.mcmc.RealSliceSampler;
import blang.mcmc.SampledVariable;
import blang.mcmc.Sampler;
import blang.mcmc.internals.SamplerBuilderContext;

import static blang.types.ExtensionUtils.*;

public class SpikedRealVarSampler implements Sampler {
  
  @SampledVariable
  SpikedRealVar variable;
  
  @ConnectedFactor
  Constrained constrained;
  
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
  public boolean setup(SamplerBuilderContext context) 
  {
    sliceSampler = RealSliceSampler.build(variable.realPart, numericFactors);
    intSampler = IntSliceSampler.build(variable.isZero, numericFactors);
    return true;
  }

}

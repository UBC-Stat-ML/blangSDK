package blang.validation.internals.fixtures;

import java.util.List;

import bayonet.distributions.Random;
import blang.core.ConstrainedFactor;
import blang.core.LogScaleFactor;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.IntNaiveMHSampler;
import blang.mcmc.RealSliceSampler;
import blang.mcmc.SampledVariable;
import blang.mcmc.Sampler;
import static blang.types.ExtensionUtils.*;

public class SpikedRealVarSampler implements Sampler {
  
  @SampledVariable
  SpikedRealVar variable;
  
  @ConnectedFactor
  ConstrainedFactor constrained;
  
  @ConnectedFactor
  List<LogScaleFactor> numericFactors;
  
  RealSliceSampler sliceSampler;
  IntNaiveMHSampler intSampler;

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
    intSampler = IntNaiveMHSampler.build(variable.isZero, numericFactors);
    return true;
  }

}

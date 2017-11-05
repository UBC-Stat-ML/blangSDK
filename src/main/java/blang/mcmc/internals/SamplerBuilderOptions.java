package blang.mcmc.internals;

import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.mcmc.Sampler;

public class SamplerBuilderOptions
{
  @Arg            @DefaultValue("true")
  public boolean useAnnotation = true; 
  
  @Arg 
  public SamplerSet additional = new SamplerSet();
  
  @Arg
  public SamplerSet excluded = new SamplerSet();
  
  public static SamplerBuilderOptions startWithOnly(Class<? extends Sampler> thisTypeOfSampler) 
  {
    SamplerBuilderOptions result = new SamplerBuilderOptions();
    result.useAnnotation = false;
    result.additional.add(thisTypeOfSampler);
    return result;
  }
}
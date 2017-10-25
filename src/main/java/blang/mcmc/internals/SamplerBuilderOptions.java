package blang.mcmc.internals;

import blang.inits.Arg;
import blang.inits.DefaultValue;

public class SamplerBuilderOptions
{
  @Arg            @DefaultValue("true")
  public boolean useAnnotation = true;
  
  @Arg 
  public SamplerSet additional = new SamplerSet();
  
  @Arg
  public SamplerSet excluded = new SamplerSet();
}
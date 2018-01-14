package blang.mcmc.internals;

import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.ExperimentResults;
import blang.mcmc.Sampler;

public class SamplerBuilderOptions
{
  @Arg(description = "If the arguments of the annotations @Samplers should be used to "
      + "determine a starting set of sampler types.")
                  @DefaultValue("true")
  public boolean useAnnotation = true; 
  
  @Arg(description = "Samplers to be added.")
  public SamplerSet additional = new SamplerSet();
  
  @Arg(description = "Samplers to be excluded (only useful if useAnnotation = true).")
  public SamplerSet excluded = new SamplerSet();
  
  public ExperimentResults monitoringStatistics = new ExperimentResults();
  
  public static SamplerBuilderOptions startWithOnly(Class<? extends Sampler> thisTypeOfSampler) 
  {
    SamplerBuilderOptions result = new SamplerBuilderOptions();
    result.useAnnotation = false;
    result.additional.add(thisTypeOfSampler);
    return result;
  }
}
package blang.mcmc.internals;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import blang.inits.DesignatedConstructor;
import blang.inits.Input;
import blang.mcmc.Sampler;

public class SamplerSet
{
  public Set<Class<Sampler>> samplers = new LinkedHashSet<>();
  
  @SuppressWarnings("unchecked")
  public void add(Class<? extends Sampler> additional) 
  {
    samplers.add((Class<Sampler>) additional);
  }
  
  @SuppressWarnings("unchecked")
  @DesignatedConstructor
  public static SamplerSet parse(@Input Optional<List<String>> qualifiedNames) throws ClassNotFoundException
  {
    SamplerSet result = new SamplerSet();
    for (String qualifiedName : qualifiedNames.orElse(Collections.emptyList()))
      result.samplers.add((Class<Sampler>) Class.forName(qualifiedName));
    return result;
  }
}
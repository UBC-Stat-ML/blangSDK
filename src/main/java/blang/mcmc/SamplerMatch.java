package blang.mcmc;

import java.util.LinkedHashSet;
import java.util.Set;
import java.util.stream.Collectors;

import blang.runtime.objectgraph.ObjectNode;

public class SamplerMatch
{
  public final Class<?> latentClass;
  public final Set<Class<? extends Sampler>> matchedSamplers;
  public SamplerMatch(ObjectNode<?> node) {
    this.latentClass = node.object.getClass();
    this.matchedSamplers = new LinkedHashSet<>();
  }
  
  @Override
  public String toString() {
    return latentClass.getSimpleName() + " sampled via: " + matchedSamplers.stream().map(c -> c.getSimpleName()).collect(Collectors.toList());
  }

  @Override
  public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + ((latentClass == null) ? 0 : latentClass.hashCode());
    result = prime * result + ((matchedSamplers == null) ? 0 : matchedSamplers.hashCode());
    return result;
  }
  @Override
  public boolean equals(Object obj) {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (getClass() != obj.getClass())
      return false;
    SamplerMatch other = (SamplerMatch) obj;
    if (latentClass == null) {
      if (other.latentClass != null)
        return false;
    } else if (!latentClass.equals(other.latentClass))
      return false;
    if (matchedSamplers == null) {
      if (other.matchedSamplers != null)
        return false;
    } else if (!matchedSamplers.equals(other.matchedSamplers))
      return false;
    return true;
  }
}
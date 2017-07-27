package blang.mcmc;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.google.common.base.Joiner;

public class BuiltSamplers
{
  public final List<Sampler> list = new ArrayList<Sampler>();
  public final Set<SamplerMatch> matchingReport = new LinkedHashSet<>();
  
  @Override
  public String toString() 
  {
    return Joiner.on("\n").join(matchingReport);
  }
}
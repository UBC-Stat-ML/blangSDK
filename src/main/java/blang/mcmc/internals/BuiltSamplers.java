package blang.mcmc.internals;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import blang.mcmc.Sampler;
import blang.runtime.internals.objectgraph.Node;

public class BuiltSamplers
{
  public final List<Sampler> list = new ArrayList<Sampler>();
  public final List<Node> correspondingVariables = new ArrayList<>();
  public final Set<SamplerMatch> matchingReport = new LinkedHashSet<>();
  
  @Override
  public String toString() 
  {
    return "" + list.size() + " samplers constructed with following prototypes:\n" + 
      matchingReport.stream().map(line -> blang.System.out.indentString + line).collect(Collectors.joining("\n"));
  }
}
package blang.engines.internals.ladders;

import java.util.List;
import java.util.Optional;

import blang.inits.Arg;
import blang.runtime.SampledModel;

public class EquallySpaced implements TemperatureLadder
{
  @Arg(description = "Number of chains, set to the number of threads if unspecified.") 
  public Optional<Integer> nChains = Optional.empty();
  
  @Override
  public void temperingParameters(
      List<Double> temperingParameters,
      List<SampledModel> initialStates,
      int nThreads) 
  { 
    temperingParameters(temperingParameters, nChains.orElse(nThreads));
  }

  private void temperingParameters(List<Double> temperingParameters, int nChains) 
  {
    if (nChains < 1)
      throw new RuntimeException("Number of tempering chains must be greater than zero.");
    if (nChains == 1)
    {
      temperingParameters.add(1.0);
      return;
    }
    for (int i = nChains - 1; i >= 0; i--)
      temperingParameters.add(((double) i) / ((double) nChains - 1.0));
  }
}

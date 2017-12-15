package blang.engines.internals.ladders;

import java.util.List;
import java.util.Optional;

import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.runtime.SampledModel;

public class Geometric implements TemperatureLadder
{
  @Arg(description = "Number of chains, set to the number of threads if unspecified.") 
  public Optional<Integer> nChains = Optional.empty();
  
  @Arg              @DefaultValue("0.8")
  public double annealingScaling = 0.8;
  
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
    if (annealingScaling < 0.0 || annealingScaling >= 1.0)
      throw new RuntimeException("Annealing scaling must be between 0 and 1 exclusively.");
    if (nChains < 1)
      throw new RuntimeException("Number of tempering chains must be greater than zero.");
    if (nChains == 1)
    {
      temperingParameters.add(1.0);
      return;
    }
    for (int i = 0; i < nChains - 1; i++)
      temperingParameters.add(Math.pow(annealingScaling, i));
    temperingParameters.add(0.0);
  }

}

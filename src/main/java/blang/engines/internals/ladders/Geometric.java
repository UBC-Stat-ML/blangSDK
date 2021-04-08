package blang.engines.internals.ladders;

import java.util.ArrayList;
import java.util.List;

import blang.inits.Arg;
import blang.inits.DefaultValue;

public class Geometric implements TemperatureLadder
{
  @Arg              @DefaultValue("0.8")
  public double annealingScaling = 0.8;
  
  @Override
  public List<Double> temperingParameters(int nChains) 
  { 
    List<Double> temperingParameters = new ArrayList<>();
    if (annealingScaling < 0.0 || annealingScaling >= 1.0)
      throw new RuntimeException("Annealing scaling must be between 0 and 1 exclusively.");
    if (nChains == 1)
      temperingParameters.add(1.0);
    else
    {
      for (int i = 0; i < nChains - 1; i++)
        temperingParameters.add(Math.pow(annealingScaling, i));
      temperingParameters.add(0.0);
    }
    return temperingParameters;
  }
}

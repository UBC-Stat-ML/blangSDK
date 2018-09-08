package blang.engines.internals.ladders;

import java.util.ArrayList;
import java.util.List;

import blang.inits.Arg;
import blang.inits.DefaultValue;

public class Polynomial implements TemperatureLadder
{
  @Arg              @DefaultValue("3")
  public double power = 3;
  
  @Override
  public List<Double> temperingParameters(int nChains) 
  {
    List<Double> temperingParameters = new ArrayList<>();
    if (power < 1.0)
      throw new RuntimeException("Annealing scaling must be between 0 and 1 exclusively.");
    if (nChains == 1)
      temperingParameters.add(1.0);
    else
      for (int i = 0; i < nChains; i++) {
        double fraction = (double) i / ((double) nChains - 1.0);
        temperingParameters.add(Math.pow((1.0 - fraction), power));
      }
    return temperingParameters;
  }
}

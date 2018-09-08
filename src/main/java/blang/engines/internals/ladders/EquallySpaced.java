package blang.engines.internals.ladders;

import java.util.ArrayList;
import java.util.List;

public class EquallySpaced implements TemperatureLadder
{
  @Override
  public List<Double> temperingParameters(int nChains) 
  {
    List<Double> temperingParameters = new ArrayList<>();
    if (nChains == 1)
      temperingParameters.add(1.0);
    else
      for (int i = nChains - 1; i >= 0; i--)
        temperingParameters.add(((double) i) / ((double) nChains - 1.0));
    return temperingParameters;
  }
}

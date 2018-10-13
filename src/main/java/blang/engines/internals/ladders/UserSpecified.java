package blang.engines.internals.ladders;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import blang.inits.Arg;

public class UserSpecified implements TemperatureLadder
{
  @Arg 
  public List<Double> annealingParameters;
  
  @Override
  public List<Double> temperingParameters(int nChains) 
  { 
    List<Double> temperingParameters = new ArrayList<>(annealingParameters);
    Collections.sort(temperingParameters);
    Collections.reverse(temperingParameters);
    if (!temperingParameters.get(0).equals(1.0))
      throw new RuntimeException();
    return temperingParameters;
  }
}

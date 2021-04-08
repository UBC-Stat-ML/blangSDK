package blang.engines.internals.ladders;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import blang.engines.internals.EngineStaticUtils;
import blang.engines.internals.Spline.MonotoneCubicSpline;
import blang.inits.Arg;
import blang.inits.DefaultValue;

public class UserSpecified implements TemperatureLadder
{
  @Arg 
  public List<Double> annealingParameters;
  
  @Arg(description = "If the command line argument 'nChains' is different, than the number of "
      + "provided grid points, allow the use of spline interpolation/extrapolation.")                        
                              @DefaultValue("false")
  public boolean allowSplineGeneralization = false;
  
  @Override
  public List<Double> temperingParameters(int nChains) 
  { 
    
    if (annealingParameters.size() != nChains) 
    {
      if (!allowSplineGeneralization)
        throw new RuntimeException("The input list of annealing parameters does not match the "
            + "number of chains requested via 'nChains'. If you want to allow linear interpolation "
            + "or extrapolation to match it, set argument 'allowLinearGeneralization' to true.");
      
      return splineGeneralization(nChains);
      
    } else {
      
      return sorted();
      
    }
    
  }
  
  public List<Double> splineGeneralization(int nChains)
  {
    List<Double> sortedAnnealingParameters = sorted();
    if (!sortedAnnealingParameters.get(sortedAnnealingParameters.size() - 1).equals(0.0))
      throw new RuntimeException();
    int swapSize = sortedAnnealingParameters.size() - 1;
    List<Double> uniform = new ArrayList<Double>(swapSize);
    for (int i = 0; i < swapSize; i++)
      uniform.add(0.1);
    Collections.reverse(sortedAnnealingParameters);
    MonotoneCubicSpline spline = EngineStaticUtils.estimateCumulativeLambda(sortedAnnealingParameters, uniform);
    return EngineStaticUtils.fixedSizeOptimalPartition(spline, nChains);
  }

  private List<Double> sorted() 
  {
    List<Double> temperingParameters = new ArrayList<>(annealingParameters);
    Collections.sort(temperingParameters);
    Collections.reverse(temperingParameters);
    if (!temperingParameters.get(0).equals(1.0))
      throw new RuntimeException();
    return temperingParameters;
  }
}

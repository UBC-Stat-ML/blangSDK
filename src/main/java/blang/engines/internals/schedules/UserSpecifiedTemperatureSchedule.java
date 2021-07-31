package blang.engines.internals.schedules;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Stack;

import bayonet.smc.ParticlePopulation;
import blang.engines.internals.EngineStaticUtils;
import blang.engines.internals.Spline.MonotoneCubicSpline;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.runtime.SampledModel;
import briefj.BriefIO;

public class UserSpecifiedTemperatureSchedule implements TemperatureSchedule
{
  @Arg        @DefaultValue("100")
  public int nTemperatures = 100;
  
  @Arg(description = "If the command line argument 'nTemperatures' is different than the number of "
      + "provided grid points, allow the use of spline interpolation/extrapolation.")                        
                              @DefaultValue("false")
  public boolean allowSplineGeneralization = false;

  @Arg(description = "Path to a line-separated file of annealing parameters.")
  public String filePath;
  
  public List<Double> annealingParameters;
  
  public Stack<Double> annealingParametersStack;
  @Override
  public double nextTemperature(ParticlePopulation<SampledModel> population, double temperature, double maxAnnealingParameter)
  {
    if (maxAnnealingParameter != 1)
      throw new UnsupportedOperationException("maxAnnealingParameter not equal to 1 is currently unsupported for this schedule.");
    if (annealingParameters == null) {
      annealingParameters = parse();
      annealingParametersStack = temperingParameters();
      annealingParametersStack.pop();
    }
    if (nTemperatures < 1)
      throw new RuntimeException("Number of temperatures should be positive: " + nTemperatures);
    Double value = annealingParametersStack.pop();
    return Math.min(maxAnnealingParameter, value);
  }
  
  
  private List<Double> parse() {
    ArrayList<Double> result = new ArrayList<Double>();
    for (String param : BriefIO.readLines(filePath).toList()) {
      Double annealingParam = Double.parseDouble(param);
      result.add(annealingParam);
    }
    boolean containsZero = false, containsOne = false;
    for (Double param : result) {
      if (param == 0)
        containsZero = true;
      if (param == 1)
        containsOne = true;
    }
    if (!containsZero)
      result.add(0.0);
    if (!containsOne)
      result.add(1.0);
    return result;
  }


  public Stack<Double> temperingParameters() 
  { 
    List<Double> tmpResult;
    Stack<Double> result = new Stack<Double>();
    if (annealingParameters.size() != nTemperatures) 
    {
      if (!allowSplineGeneralization)
        throw new RuntimeException("The input list of annealing parameters does not match the "
            + "number of temperatures requested via 'nTemperatures'. If you want to allow linear interpolation "
            + "or extrapolation to match it, set argument 'allowLinearGeneralization' to true.");
      
      tmpResult = splineGeneralization();
      Collections.reverse(tmpResult);
      result.addAll(tmpResult);
      
    } else {
      
      tmpResult = sorted();
      result.addAll(tmpResult);
      
    }
    
    return result;
  }
  
  public List<Double> splineGeneralization()
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
    return EngineStaticUtils.fixedSizeOptimalPartition(spline, nTemperatures);
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
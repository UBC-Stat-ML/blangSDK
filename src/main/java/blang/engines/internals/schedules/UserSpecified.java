package blang.engines.internals.schedules;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import bayonet.smc.ParticlePopulation;
import blang.inits.ConstructorArg;
import blang.inits.DesignatedConstructor;
import blang.runtime.SampledModel;

public class UserSpecified implements TemperatureSchedule
{
  Map<Double, Double> next;
  
  @DesignatedConstructor
  public UserSpecified(@ConstructorArg("annealingParameters") List<Double> annealingParameters)
  {
    set(annealingParameters);
  }
  
  public void set(List<Double> annealingParameters) 
  {
    annealingParameters = new ArrayList<>(annealingParameters);
    Collections.sort(annealingParameters);
    if (annealingParameters.get(0) != 0.0 || annealingParameters.get(annealingParameters.size()-1) != 1.0)
      throw new RuntimeException();
    next = new HashMap<>();
    for (int i = 0; i < annealingParameters.size() - 1; i++) 
      next.put(annealingParameters.get(i), annealingParameters.get(i + 1));
    if (next.size() != annealingParameters.size() - 1)
      throw new RuntimeException();
  }

  @Override
  public double nextTemperature(ParticlePopulation<SampledModel> population, double temperature, double maxAnnealingParameter)
  {
    return next.get(temperature);
  }
}
package blang.engines.internals.schedules;

import bayonet.smc.ParticlePopulation;
import blang.inits.Implementations;
import blang.runtime.SampledModel;

@Implementations({AdaptiveTemperatureSchedule.class, FixedTemperatureSchedule.class, UserSpecifiedTemperatureSchedule.class})
public interface TemperatureSchedule
{
  double nextTemperature(ParticlePopulation<SampledModel> population, double annealingParam, double maxAnnealParam);
}

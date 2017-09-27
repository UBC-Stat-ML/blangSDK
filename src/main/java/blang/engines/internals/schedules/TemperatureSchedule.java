package blang.engines.internals.schedules;

import bayonet.smc.ParticlePopulation;
import blang.engines.internals.AnnealedParticle;
import blang.inits.Implementations;

@Implementations({AdaptiveTemperatureSchedule.class, FixedTemperatureSchedule.class}) 
public interface TemperatureSchedule
{
  double nextTemperature(ParticlePopulation<? extends AnnealedParticle> population, double temperature);
}
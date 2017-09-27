package blang.engines.internals.schedules;

import bayonet.smc.ParticlePopulation;
import blang.engines.internals.AnnealedParticle;
import blang.inits.Arg;
import blang.inits.DefaultValue;

public class FixedTemperatureSchedule implements TemperatureSchedule
{
  @Arg        @DefaultValue("100")
  public int nTemperatures = 100;

  @Override
  public double nextTemperature(ParticlePopulation<? extends AnnealedParticle> population, double temperature)
  {
    return Math.min(1.0, temperature + 1.0 / ((double) nTemperatures));
  }
}
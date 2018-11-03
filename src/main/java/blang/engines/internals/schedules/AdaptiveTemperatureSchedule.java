package blang.engines.internals.schedules;

import java.io.Writer;

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.analysis.solvers.PegasusSolver;

import bayonet.smc.ParticlePopulation;
import blang.engines.internals.EngineStaticUtils;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.DesignatedConstructor;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import briefj.BriefIO;

public class AdaptiveTemperatureSchedule implements TemperatureSchedule
{
  @Arg(description = "See Zhou, Johansen and Aston (2013).")
                   @DefaultValue("true")
  public boolean useConditional = true;
  
  @Arg(description = "Annealing parameter is selected to get the (conditional) "
      + "ESS decrease specified by this parameter.")
             @DefaultValue("0.9999")
  public double threshold = 0.9999;
  
  @Arg(description = "If all particles are out of support at first iteration, nudge the temperature a bit so that support constraints kick in.")
                               @DefaultValue("1e-10") // TODO: fix using the Alive Particle Sampler paper? 
  public double nudgeFromZeroIfOutOfSupport = 1e-10; // we do not want constraints at temperature zero so that normalization constant is known there
  
  final Writer log;
  int iter = 0;
  
  public AdaptiveTemperatureSchedule()
  {
    log = null;
  }
  
  @DesignatedConstructor
  public AdaptiveTemperatureSchedule(@GlobalArg ExperimentResults results)
  {
    log = results.child(Runner.MONITORING_FOLDER).getAutoClosedBufferedWriter("temperatures.csv");
    BriefIO.println(log, "iteration,temperature");
  }
  
  @Override
  public double nextTemperature(ParticlePopulation<SampledModel> population, double temperature, double maxAnnealingParameter)
  {
    if (!(threshold > 0.0 && threshold < 1.0))
      throw new RuntimeException("The adaptive tempering threshold should be between 0 and 1 (exclusive): " + threshold);
    UnivariateFunction objective = objective(population, temperature);
    
    if (Double.isNaN(objective.value(1.0))) // Here we do mean 1.0 - by design this guarantees support is checked
    {
      // every single particle is out of support
      temperature = Math.max(temperature, nudgeFromZeroIfOutOfSupport);
      System.out.println("Warning: Every particle out of support; this removes guarantees on logZ estimate; will next use temperature: " + temperature);
      return temperature;
    }
    
    double nextTemperature = objective.value(maxAnnealingParameter) >= 0 ? 
      maxAnnealingParameter :
      new PegasusSolver().solve(100, objective, temperature, maxAnnealingParameter);
    if (log != null)
      BriefIO.println(log, "" + iter++ + "," + nextTemperature);
    return nextTemperature;
  }

  private UnivariateFunction objective(ParticlePopulation<SampledModel> population, double temperature)
  {
    double previousRelativeESS = useConditional ? Double.NaN : population.getRelativeESS();
    return useConditional ? 
        (double proposedNextTemperature) -> EngineStaticUtils.relativeESS(population, temperature, proposedNextTemperature, true)  - threshold:
        (double proposedNextTemperature) -> EngineStaticUtils.relativeESS(population, temperature, proposedNextTemperature, false) - threshold * previousRelativeESS;
  }
}
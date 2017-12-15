package blang.engines.internals.schedules;

import java.io.Writer;

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.analysis.solvers.PegasusSolver;

import bayonet.smc.ParticlePopulation;
import blang.engines.internals.SMCStaticUtils;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.DesignatedConstructor;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.runtime.SampledModel;
import briefj.BriefIO;

public class AdaptiveTemperatureSchedule implements TemperatureSchedule
{
  @Arg             @DefaultValue("true")
  public boolean useConditional = true;
  
  @Arg       @DefaultValue("0.9999")
  public double threshold = 0.9999;
  
  final Writer log;
  int iter = 0;
  
  public AdaptiveTemperatureSchedule()
  {
    log = null;
  }
  
  @DesignatedConstructor
  public AdaptiveTemperatureSchedule(@GlobalArg ExperimentResults results)
  {
    log = results.getAutoClosedBufferedWriter("temperatures.csv");
    BriefIO.println(log, "iteration,temperature");
  }
  
  @Override
  public double nextTemperature(ParticlePopulation<SampledModel> population, double temperature)
  {
    UnivariateFunction objective = objective(population, temperature);
    double nextTemperature = objective.value(1.0) >= 0 ? 
      1.0 :
      new PegasusSolver().solve(100, objective, temperature, 1.0);
    if (log != null)
      BriefIO.println(log, "" + iter++ + "," + nextTemperature);
    return nextTemperature;
  }

  private UnivariateFunction objective(ParticlePopulation<SampledModel> population, double temperature)
  {
    double previousRelativeESS = useConditional ? Double.NaN : population.getRelativeESS();
    return useConditional ? 
        (double proposedNextTemperature) -> SMCStaticUtils.relativeESS(population, temperature, proposedNextTemperature, true)  - threshold:
        (double proposedNextTemperature) -> SMCStaticUtils.relativeESS(population, temperature, proposedNextTemperature, false) - threshold * previousRelativeESS;
  }
}
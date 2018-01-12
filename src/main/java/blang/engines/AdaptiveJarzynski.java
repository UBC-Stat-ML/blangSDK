package blang.engines;

import java.util.Arrays;

import bayonet.distributions.Random;
import bayonet.smc.ParticlePopulation;
import bayonet.smc.ResamplingScheme;
import blang.engines.internals.schedules.AdaptiveTemperatureSchedule;
import blang.engines.internals.schedules.TemperatureSchedule;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.Cores;
import blang.runtime.SampledModel;
import briefj.BriefParallel;

public class AdaptiveJarzynski
{
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  @Arg                    @DefaultValue("0.5")
  public double resamplingESSThreshold = 0.5;
  
  @Arg                                  @DefaultValue("AdaptiveTemperatureSchedule")
  public TemperatureSchedule temperatureSchedule = new AdaptiveTemperatureSchedule();
  
  @Arg                                         @DefaultValue("STRATIFIED")            
  public ResamplingScheme resamplingScheme = ResamplingScheme.STRATIFIED;

  @Arg     @DefaultValue("1_000")
  public int nParticles = 1_000;

  @Arg   
  public Cores nThreads = Cores.maxAvailable(); 
  
  protected SampledModel prototype;
  protected Random [] parallelRandomStreams;
  
  /**
   * @return The particle population at the last step
   */
  public ParticlePopulation<SampledModel> getApproximation(SampledModel model)
  {
    prototype = model;
    parallelRandomStreams = Random.parallelRandomStreams(random, nParticles);
    
    ParticlePopulation<SampledModel> population = initialize(parallelRandomStreams);
    
    int iter = 0;
    double temperature = 0.0;
    while (temperature < 1.0)
    {
      double nextTemperature = temperatureSchedule.nextTemperature(population, temperature); 
      population = propose(parallelRandomStreams, population, temperature, nextTemperature);
      if (resamplingNeeded(population, nextTemperature))
      {
        population = resample(random, population);
        System.out.println("Resampling [iter=" + iter + ", Z_{" + nextTemperature + "}= " + population.logNormEstimate() + "]");
      }
      temperature = nextTemperature;
      iter++;
    }
    System.out.println("Change of measure complete [iter=" + iter + ", Z=" + population.logNormEstimate() + "]");
    return population;
  }
  
  private boolean resamplingNeeded(ParticlePopulation<SampledModel> population, double nextTemperature) 
  {
    for (int i = 0; i < population.nParticles(); i++)
      if (population.getNormalizedWeight(i) == 0.0)
        return true;
    return population.getRelativeESS() < resamplingESSThreshold && nextTemperature < 1.0;
  }

  private ParticlePopulation<SampledModel> resample(Random random, ParticlePopulation<SampledModel> population)
  {
    population = population.resample(random, resamplingScheme);
    deepCopyParticles(population);
    return population;
  }

  protected void deepCopyParticles(final ParticlePopulation<SampledModel> population) 
  {
    SampledModel [] cloned = (SampledModel[]) new SampledModel[nParticles];
    
    BriefParallel.process(nParticles, nThreads.available, particleIndex ->
    {
      SampledModel current = population.particles.get(particleIndex);
      boolean needsCloning = particleIndex > 0 && current == population.particles.get(particleIndex - 1);
      cloned[particleIndex] = needsCloning ? current.duplicate() : current;
    });
    
    for (int i = 0; i < nParticles; i++)
      population.particles.set(i, cloned[i]);
  }

  private ParticlePopulation<SampledModel> propose(Random [] randoms, final ParticlePopulation<SampledModel> currentPopulation, double temperature, double nextTemperature)
  {
    final boolean isInitial = currentPopulation == null;
    
    final double [] logWeights = new double[nParticles];
    final SampledModel [] particles = (SampledModel[]) new SampledModel[nParticles];
    
    BriefParallel.process(nParticles, nThreads.available, particleIndex ->
    {
      Random random = randoms[particleIndex];
      logWeights[particleIndex] = 
        (isInitial ? 0.0 : currentPopulation.particles.get(particleIndex).logDensityRatio(temperature, nextTemperature) + Math.log(currentPopulation.getNormalizedWeight(particleIndex)));
      // Note: order important since computation is done in place: weight computation should be done first
      SampledModel proposed = isInitial ?
          sampleInitial(random) :
          sampleNext(random, currentPopulation.particles.get(particleIndex), nextTemperature);
      particles[particleIndex] = proposed;
    });
    
    return ParticlePopulation.buildDestructivelyFromLogWeights(
        logWeights, 
        Arrays.asList(particles),
        isInitial ? 0.0 : currentPopulation.logScaling);
  }
  
  private SampledModel sampleInitial(Random random)
  {
    SampledModel copy = prototype.duplicate();
    copy.setExponent(0.0);
    copy.forwardSample(random, false);
    copy.dropForwardSimulator();
    return copy;
  }
  
  private SampledModel sampleNext(Random random, SampledModel current, double temperature)
  {
    current.setExponent(temperature);
    current.posteriorSamplingStep_deterministicScanAndShuffle(random); 
    return current;
  }
  
  private ParticlePopulation<SampledModel> initialize(Random [] randoms)
  {
    return propose(randoms, null, Double.NaN, Double.NaN);
  }
}

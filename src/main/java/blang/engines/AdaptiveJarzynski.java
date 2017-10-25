package blang.engines;

import java.util.Arrays;

import bayonet.distributions.Random;
import bayonet.smc.ParticlePopulation;
import bayonet.smc.ResamplingScheme;
import blang.engines.internals.AnnealedParticle;
import blang.engines.internals.AnnealingKernels;
import blang.engines.internals.schedules.AdaptiveTemperatureSchedule;
import blang.engines.internals.schedules.TemperatureSchedule;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.Cores;
import briefj.BriefParallel;

public class AdaptiveJarzynski<P extends AnnealedParticle> 
{
  @Arg                    @DefaultValue("0.5")
  public double resamplingESSThreshold = 0.5;
  
  @Arg                                  @DefaultValue("AdaptiveTemperatureSchedule")
  public TemperatureSchedule temperatureSchedule = new AdaptiveTemperatureSchedule();
  
  @Arg                                         @DefaultValue("STRATIFIED")            
  public ResamplingScheme resamplingScheme = ResamplingScheme.STRATIFIED;

  @Arg                 @DefaultValue("10_000")
  public int nSamplesPerTemperature = 10_000;

  @Arg   
  public Cores nThreads = Cores.maxAvailable(); 
  
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  AnnealingKernels<P> kernels;
  
  /**
   * @return The particle population at the last step
   */
  public ParticlePopulation<P> getApproximation(AnnealingKernels<P> kernels)
  {
    this.kernels = kernels;
    Random [] parallelRandomStreams = Random.parallelRandomStreams(random, nSamplesPerTemperature);
    ParticlePopulation<P> population = initialize(parallelRandomStreams);
    
    double temperature = 0.0;
    while (temperature < 1.0)
    {
      double nextTemperature = temperatureSchedule.nextTemperature(population, temperature); 
      population = propose(parallelRandomStreams, population, temperature, nextTemperature);
      if (resamplingNeeded(population, nextTemperature))
        population = resample(random, population);
      temperature = nextTemperature;
    }
    return population;
  }
  
  private boolean resamplingNeeded(ParticlePopulation<P> population, double nextTemperature) 
  {
    for (int i = 0; i < population.nParticles(); i++)
      if (population.getNormalizedWeight(i) == 0.0)
        return true;
    return population.getRelativeESS() < resamplingESSThreshold && nextTemperature < 1.0;
  }

  private ParticlePopulation<P> resample(Random random, ParticlePopulation<P> population)
  {
    population = population.resample(random, resamplingScheme);
    if (kernels.inPlace())
      deepCopyParticles(population);
    return population;
  }

  private void deepCopyParticles(final ParticlePopulation<P> population) 
  {
    @SuppressWarnings("unchecked")
    P [] cloned = (P[]) new AnnealedParticle[nSamplesPerTemperature];
    
    BriefParallel.process(nSamplesPerTemperature, nThreads.available, particleIndex ->
    {
      boolean needsCloning = particleIndex > 1 && population.particles.get(particleIndex) == population.particles.get(particleIndex - 1);
      P current = population.particles.get(particleIndex);
      cloned[particleIndex] = needsCloning ? kernels.deepCopy(current) : current;
    });
    
    for (int i = 0; i < nSamplesPerTemperature; i++)
      population.particles.set(i, cloned[i]);
  }

  private ParticlePopulation<P> propose(Random [] randoms, final ParticlePopulation<P> currentPopulation, double temperature, double nextTemperature)
  {
    final boolean isInitial = currentPopulation == null;
    
    final double [] logWeights = new double[nSamplesPerTemperature];
    @SuppressWarnings("unchecked")
    final P [] particles = (P[]) new AnnealedParticle[nSamplesPerTemperature];
    
    BriefParallel.process(nSamplesPerTemperature, nThreads.available, particleIndex ->
    {
      P proposed = isInitial ?
        kernels.sampleNext(randoms[particleIndex], null, 0.0) :
        kernels.sampleNext(randoms[particleIndex], currentPopulation.particles.get(particleIndex), nextTemperature);
      logWeights[particleIndex] = 
        (isInitial ? 0.0 : currentPopulation.particles.get(particleIndex).logDensityRatio(temperature, nextTemperature) + Math.log(currentPopulation.getNormalizedWeight(particleIndex)));
      particles[particleIndex] = proposed;
    });
    
    return ParticlePopulation.buildDestructivelyFromLogWeights(
        logWeights, 
        Arrays.asList(particles),
        isInitial ? 0.0 : currentPopulation.logScaling);
  }
  
  private ParticlePopulation<P> initialize(Random [] randoms)
  {
    return propose(randoms, null, Double.NaN, Double.NaN);
  }
}

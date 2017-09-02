package blang.algo;

import java.util.Arrays;

import bayonet.distributions.ExhaustiveDebugRandom;
import bayonet.distributions.Random;
import bayonet.smc.ParticlePopulation;
import bayonet.smc.ResamplingScheme;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import briefj.BriefParallel;
import blang.algo.schedules.AdaptiveTemperatureSchedule;
import blang.algo.schedules.TemperatureSchedule;

// TODO: move to separate project
public class ChangeOfMeasureSMC<P extends AnnealedParticle> 
{
  @Arg                    @DefaultValue("0.5")
  public double resamplingESSThreshold = 0.5;
  
  @Arg                                  @DefaultValue("AdaptiveTemperatureSchedule")
  public TemperatureSchedule temperatureSchedule = new AdaptiveTemperatureSchedule();
  
  @Arg                                         @DefaultValue("MULTINOMIAL")            
  public ResamplingScheme resamplingScheme = ResamplingScheme.MULTINOMIAL;

  @Arg     @DefaultValue("1_000")
  public int nSamplesPerTemperature = 1_000;

  @Arg   @DefaultValue("1")
  public int nThreads = 1;
  
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  AnnealingKernels<P> kernels;
  
  /**
   * @return The particle population at the last step
   */
  public ParticlePopulation<P> getApproximation()
  {
    Random [] parallelRandomStreams = Random.parallelRandomStreams(random, nSamplesPerTemperature);
    ParticlePopulation<P> population = initialize(parallelRandomStreams);
    
    double temperature = 0.0;
    while (temperature < 1.0)
    {
      double nextTemperature = temperatureSchedule.nextTemperature(population, temperature); 
      population = propose(parallelRandomStreams, population, temperature, nextTemperature);
      if (population.getRelativeESS() < resamplingESSThreshold && nextTemperature < 1.0)
        population = resample(random, population); 
      temperature = nextTemperature;
    }
    return population;
  }
  
  private ParticlePopulation<P> resample(Random random, ParticlePopulation<P> population)
  {
    if (kernels.inPlace() && random instanceof ExhaustiveDebugRandom)
      throw new RuntimeException();
    population = population.resample(random, resamplingScheme);
    if (kernels.inPlace())
    {
      P previous = null;
      for (int i = 0; i < nSamplesPerTemperature; i++)
      {
        P current = population.particles.get(i);
        if (current == previous)
          population.particles.set(i, kernels.deepCopy(current)); 
        previous = current;
      }
    }
    return population;
  }

  private ParticlePopulation<P> propose(Random [] randoms, final ParticlePopulation<P> currentPopulation, double temperature, double nextTemperature)
  {
    final boolean isInitial = currentPopulation == null;
    
    final double [] logWeights = new double[nSamplesPerTemperature];
    @SuppressWarnings("unchecked")
    final P [] particles = (P[]) new AnnealedParticle[nSamplesPerTemperature];
    
    BriefParallel.process(nSamplesPerTemperature, nThreads, particleIndex ->
    {
      P proposed = isInitial ?
        kernels.sampleInitial(randoms[particleIndex]) :
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

  public void setKernels(AnnealingKernels<P> kernels)
  {
    this.kernels = kernels;
  }
}

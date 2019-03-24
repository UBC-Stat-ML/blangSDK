package blang.engines;

import java.util.Arrays;

import org.eclipse.xtext.xbase.lib.Pair;

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

import blang.System;

public class AdaptiveJarzynski
{
  @Arg(description = "Random seed used for proposals and resampling.")
                     @DefaultValue("1")
  public Random random = new Random(1);
  
  @Arg(description = "If the (relative) Effective Sample Size (ESS) falls below, "
      + "perform a resampling round.")
                          @DefaultValue("0.5")
  public double resamplingESSThreshold = 0.5;
  
  @Arg(description = "Algorithm selecting annealing parameter increments.")
                                        @DefaultValue("AdaptiveTemperatureSchedule")
  public TemperatureSchedule temperatureSchedule = new AdaptiveTemperatureSchedule();
  
  @Arg                                         @DefaultValue("STRATIFIED")            
  public ResamplingScheme resamplingScheme = ResamplingScheme.STRATIFIED;

  @Arg     @DefaultValue("1_000")
  public int nParticles = 1_000;

  @Arg           @DefaultValue("Dynamic")
  public Cores nThreads = Cores.dynamic();
  
  @Arg(description = "Use higher values for likelihood maximization")
                         @DefaultValue("1.0")
  public double maxAnnealingParameter = 1.0;
  
  protected SampledModel prototype;
  protected Random [] parallelRandomStreams;
  
  private boolean dropForwardSimulator; // e.g. do not want to drop them when initializing PT
  
  /**
   * @return The particle population at the last step
   */
  public ParticlePopulation<SampledModel> getApproximation(SampledModel model)
  {
    Random [] parallelRandomStreams = Random.parallelRandomStreams(random, nParticles);
    return getApproximation(initialize(model, parallelRandomStreams), maxAnnealingParameter, model, parallelRandomStreams, true);
  }
  
  /**
   * Lower-level version used for initialization of other methods
   */
  public ParticlePopulation<SampledModel> getApproximation(
      ParticlePopulation<SampledModel> initial, 
      double maxAnnealingParameter,
      SampledModel prototype,
      Random [] parallelRandomStreams,
      boolean dropForwardSimulator
      )
  {
    this.dropForwardSimulator = dropForwardSimulator;
    if (initial.nParticles() != nParticles)
      throw new RuntimeException();
    this.prototype = prototype;
    this.parallelRandomStreams = parallelRandomStreams;
    
    ParticlePopulation<SampledModel> population = initial;
    
    int iter = 0;
    double temperature = population.particles.get(0).getExponent();
    while (temperature < maxAnnealingParameter)
    {
      double nextTemperature = temperatureSchedule.nextTemperature(population, temperature, maxAnnealingParameter); 
      // TODO: slight optimization, probably not worth it: could know at this point if resampling is needed, 
      // and which particles will survive, so if a particle has no offspring no need to actually sample it.
      population = propose(parallelRandomStreams, population, temperature, nextTemperature);
      recordPropagationStatistics(iter, temperature, population.getRelativeESS());
      if (resamplingNeeded(population, nextTemperature))
      { 
        population = resample(random, population);
        recordResamplingStatistics(iter, nextTemperature, population.logNormEstimate());
        
      }
      temperature = nextTemperature;
      iter++;
    }
    return population;
  }
  
  private boolean resamplingNeeded(ParticlePopulation<SampledModel> population, double nextTemperature) 
  {
    for (int i = 0; i < population.nParticles(); i++)
      if (population.getNormalizedWeight(i) == 0.0)
        return true;
    return population.getRelativeESS() < resamplingESSThreshold && nextTemperature < maxAnnealingParameter;
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
    
    BriefParallel.process(nParticles, nThreads.numberAvailable(), particleIndex -> 
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
    
    BriefParallel.process(nParticles, nThreads.numberAvailable(), particleIndex ->
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
    if (dropForwardSimulator)
      copy.dropForwardSimulator();
    return copy;
  }
  
  private SampledModel sampleNext(Random random, SampledModel current, double temperature)
  {
    current.setExponent(temperature);
    current.posteriorSamplingStep(random); 
    return current;
  }
  
  public ParticlePopulation<SampledModel> initialize(SampledModel prototype, Random [] randoms)
  {
    this.prototype = prototype;
    return propose(randoms, null, Double.NaN, Double.NaN);
  }
  
  protected void recordPropagationStatistics(int iteration, double temperature, double ess) 
  {
    System.out.formatln("Propagation", 
      "[", 
        Pair.of("annealParam", temperature), 
        Pair.of("ess", ess), 
      "]");
  }
  
  protected void recordResamplingStatistics(int iter, double nextTemperature, double logNormalization)
  {
    System.out.formatln("Resampling", 
      "[", 
        Pair.of("iter", iter), 
        Pair.of("annealParam", nextTemperature), 
        Pair.of("logNormalization", logNormalization), 
      "]");
  }
}

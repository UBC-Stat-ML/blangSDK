package blang.engines;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
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
  
  @Arg(description = "If false, do only one move between annealing param change, otherwise do nPassesPerScan scans")
                             @DefaultValue("false")
  public boolean usePosteriorSamplingScan = false;

  @Arg            @DefaultValue("3")
  public double nPassesPerScan = 3;

  @Arg(description = "Use higher values for likelihood maximization")
                         @DefaultValue("1.0")
  public double maxAnnealingParameter = 1.0;
  
  @Arg(description = "Save log weights over iterations.")
                  @DefaultValue("false")
  public boolean recordWeights = false;
  
  @Arg(description = "Estimate not only Z_1 but also Z_beta for all annealing parameters beta visited.")
                          @DefaultValue("false")
  public boolean estimateFullZFunction = false;
  
  @Arg(description = "Perform nPassesPerScan scans after each resampling event.")
                                    @DefaultValue("false")
  public boolean resamplingTriggeredRejuvenation = false;
  
  public int nResamplingRounds;

  protected SampledModel prototype;
  protected Random [] parallelRandomStreams;
  
  public List<Double> fullZFunction = null;        // entry i estimates Z_{beta_i}
  public List<Double> energySDs = null;            // entry i estimates SD[ V_{beta_i} ]
  public List<Double> annealingParameters = null;  // beta_i
  
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
    nResamplingRounds = 0;
    this.dropForwardSimulator = dropForwardSimulator;
    if (initial.nParticles() != nParticles)
      throw new RuntimeException();
    this.prototype = prototype;
    this.parallelRandomStreams = parallelRandomStreams;
    
    ParticlePopulation<SampledModel> population = initial;
    
    if (estimateFullZFunction) {
      fullZFunction.add(0.0);
      annealingParameters.add(0.0);
    }
    
    int iter = 0;
    double temperature = population.particles.get(0).getExponent();
    while (temperature < maxAnnealingParameter)
    {
      double nextTemperature = temperatureSchedule.nextTemperature(population, temperature, maxAnnealingParameter); 
      // TODO: slight optimization, probably not worth it: could know at this point if resampling is needed, 
      // and which particles will survive, so if a particle has no offspring no need to actually sample it.
      population = propose(parallelRandomStreams, population, temperature, nextTemperature);
      if (estimateFullZFunction) {
        fullZFunction.add(population.logNormEstimate());
        annealingParameters.add(nextTemperature);
        
      }
      recordPropagationStatistics(iter, nextTemperature, population.getRelativeESS(), population.logNormEstimate());
      if (resamplingNeeded(population, nextTemperature))
      { 
        population = resample(random, population);
        recordResamplingStatistics(iter, nextTemperature, population.logNormEstimate());
        recordAncestry(iter, population.ancestors, temperature);
        nResamplingRounds++;
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
    final ParticlePopulation<SampledModel> result = population;
    
    if (resamplingTriggeredRejuvenation) {
      BriefParallel.process(nParticles, nThreads.numberAvailable(), particleIndex ->
      {
        Random rand = parallelRandomStreams[particleIndex];
        for (int i = 0; i < nPassesPerScan; i++)
          result.particles.get(particleIndex).posteriorSamplingScan(rand);
      });
    }
    
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
    final double [] energies = estimateFullZFunction ? new double[nParticles] : null;
    final SampledModel [] particles = (SampledModel[]) new SampledModel[nParticles];
    final double inverseNegativeIncrement = 1.0 / (temperature - nextTemperature);
    
    BriefParallel.process(nParticles, nThreads.numberAvailable(), particleIndex ->
    {
      Random random = randoms[particleIndex];
      double incrementalLogWeight = isInitial ? 0.0 : currentPopulation.particles.get(particleIndex).logDensityRatio(temperature, nextTemperature);
      if (estimateFullZFunction && !isInitial) {
        energies[particleIndex] = incrementalLogWeight * inverseNegativeIncrement;
      }
      logWeights[particleIndex] = 
        (isInitial ? 0.0 : incrementalLogWeight + Math.log(currentPopulation.getNormalizedWeight(particleIndex)));
      // Note: order important since computation is done in place: weight computation should be done first
      SampledModel proposed = isInitial ?
          sampleInitial(random) :
          sampleNext(random, currentPopulation.particles.get(particleIndex), nextTemperature);
      particles[particleIndex] = proposed;
    });

    if (recordWeights)
      recordLogWeights(logWeights, nextTemperature);
    
    if (estimateFullZFunction && !isInitial)
    {
      SummaryStatistics stats = new SummaryStatistics();
      for (double e : energies)
        stats.addValue(e);
      if (!Double.isFinite(stats.getStandardDeviation()))
        energySDs.add(robustSD(energies, stats)); // work around needed by e.g. ode.MRNATransfection in blangDemo b/c of extreme but finite values in the energy
      else
        energySDs.add(stats.getStandardDeviation());
    }
    
    return ParticlePopulation.buildDestructivelyFromLogWeights(
        logWeights, 
        Arrays.asList(particles),
        null,
        isInitial ? 0.0 : currentPopulation.logScaling);
  }
  
  private static double robustSD(double [] numbers, SummaryStatistics stats) 
  {
    double m = stats.getMean();
    double spread = Math.max(stats.getMax() - m, m - stats.getMin());
    SummaryStatistics transf = new SummaryStatistics();
    for (double n : numbers) {
      transf.addValue((n - m)/spread);
    }
    return transf.getStandardDeviation() * spread;
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
    if (usePosteriorSamplingScan)
      current.posteriorSamplingScan(random, nPassesPerScan);
    else
      current.posteriorSamplingStep(random);

    return current;
  }
  
  public ParticlePopulation<SampledModel> initialize(SampledModel prototype, Random [] randoms)
  {
    this.fullZFunction        = estimateFullZFunction ? new ArrayList<Double>() : null;
    this.annealingParameters  = estimateFullZFunction ? new ArrayList<Double>() : null;
    this.energySDs            = estimateFullZFunction ? new ArrayList<Double>() : null;
    
    this.prototype = prototype;
    return propose(randoms, null, Double.NaN, Double.NaN);
  }
  
  protected void recordLogWeights(double [] weights, double temperature) {}
  protected void recordAncestry(int iteration, List<Integer> ancestors, double temperature) {}

  protected void recordPropagationStatistics(int iteration, double temperature, double ess, double logNorm)
  {
    System.out.formatln("Propagation", 
      "[", 
        Pair.of("annealParam", temperature), 
        Pair.of("ess", ess), 
        Pair.of("logNormalization", logNorm),
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

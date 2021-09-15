package blang.engines.internals.factories;

import java.util.List;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.Random;
import bayonet.math.NumericalUtils;
import bayonet.smc.ParticlePopulation;
import blang.engines.AdaptiveJarzynski;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.engines.internals.schedules.AdaptiveTemperatureSchedule;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.inits.experiments.tabwriters.TidySerializer;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefParallel;

import blang.System;

/**
 * Sequential Change of Measure implementation.
 */
public class SCM extends AdaptiveJarzynski implements PosteriorInferenceEngine
{
  @GlobalArg public ExperimentResults results = new ExperimentResults();

  @Arg(description = "Number of rejuvenation passes to do after the change of measure.")     
                    @DefaultValue("5")
  public int nFinalRejuvenations = 5;

  SampledModel model;
  
  @Override
  public void setSampledModel(SampledModel model) 
  { 
    this.model = model;
  }

  @Override
  public void performInference() 
  {
    // create approx
    ParticlePopulation<SampledModel> approximation = getApproximation(model);
    recordZ(approximation);
    recordRelativeVarZ(approximation);
    resampleLastIteration(approximation);
    rejuvenate(parallelRandomStreams, approximation);
    writeSamples(approximation);
  }

  private void resampleLastIteration(ParticlePopulation<SampledModel> approximation) {
    if (!isUniform(approximation)) // could happen if there were zero-weight particles in last round
      approximation = approximation.resample(random, resamplingScheme);
  }

  @SuppressWarnings("unchecked")
  private void writeSamples(ParticlePopulation<SampledModel> approximation) {
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    BlangTidySerializer densitySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    int particleIndex = 0;
    for (SampledModel model : approximation.particles)  
    {
      model.getSampleWriter(tidySerializer).write(Pair.of(Runner.sampleColumn, particleIndex)); 
      densitySerializer.serialize(model.logDensity(), "logDensity", Pair.of(Runner.sampleColumn, particleIndex));
      particleIndex++;
    }
  }

  private void recordRelativeVarZ(ParticlePopulation<SampledModel> approximation) {
    // TODO: implement this for SCM in the general case, i.e., compute CESS and accumulate.
    if (temperatureSchedule instanceof AdaptiveTemperatureSchedule)
      recordRelativeVarZ(relVarFactorizationMethodName, logRelativeVarZ());
  }

  private void recordZ(ParticlePopulation<SampledModel> approximation) {
    double logNormEstimate = approximation.logNormEstimate();
    System.out.println("Log normalization constant estimate: " + logNormEstimate);
    results.getTabularWriter(Runner.LOG_NORMALIZATION_ESTIMATE).write(
        Pair.of(Runner.LOG_NORMALIZATION_ESTIMATOR, "SCM"),
        Pair.of(TidySerializer.VALUE, logNormEstimate)
    );
  }

  public static boolean isUniform(ParticlePopulation<?> pop)
  {
    for (int i = 0; i < pop.nParticles(); i++) 
      if (pop.getNormalizedWeight(i) != 1.0 / ((double) pop.nParticles()))
        return false;
    return true;
  }
  
  private void rejuvenate(Random [] randoms, final ParticlePopulation<SampledModel> finalPopulation)
  {
    if (nFinalRejuvenations <= 0)
      return;
    System.out.println("Final rejuvenation started");
    deepCopyParticles(finalPopulation);
    BriefParallel.process(nParticles, nThreads.numberAvailable(), particleIndex ->
    {
      Random random = randoms[particleIndex];
      for (int i = 0; i < nFinalRejuvenations; i++)
        finalPopulation.particles.get(particleIndex).posteriorSamplingScan(random);
    });
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    // TODO: may want to check forward simulators ok
    return;
  }
  
  public static final String
  
    relVarFactorizationMethodName = "factorizationMethod",

    propagationFileName = "propagation",
    ancestryFileName = "ancestry",
    resamplingFileName = "resampling",
    weightsFileName = "weights",
    chiSquareFileName = "chiSquare",
    
    essColumn = "ess",
    logNormalizationColumn = "logNormalization",
    iterationColumn = "iteration",
    particleColumn = "particle",
    ancestorColumn = "ancestor",
    weightColumn = "logWeight",
    estimatorColumn = "estimator",
    logRelVarColumn = "logRelativeVarianceZ",
    annealingParameterColumn = "annealingParameter";

  protected double logRelativeVarZ()
  {
    double numIter = ((AdaptiveTemperatureSchedule) temperatureSchedule).getNumIter();
    double delta = ((AdaptiveTemperatureSchedule) temperatureSchedule).getChiSquareDivergenceParameter();
    double log1pRelativeVar = numIter * NumericalUtils.logAdd(0, Math.log(delta) - Math.log(nParticles));
    // Note: logDifference(x,y) returns log|exp(x)-exp(y)| and log1pRelativeVar > 1
    return NumericalUtils.logDifference(log1pRelativeVar, 0);
  }

  protected void recordRelativeVarZ(String estimatorName, double logRelativeVarZ)
  {
    results.child(Runner.MONITORING_FOLDER).getTabularWriter(chiSquareFileName).write(
        Pair.of(estimatorColumn, estimatorName),
        Pair.of(logRelVarColumn, logRelativeVarZ)
    );
    System.out.println("RelativeVariance(Z) estimate (" + estimatorName + "): " + logRelativeVarZ);
  }

  @Override
  protected void recordLogWeights(double [] weights, double temperature)
  {
    int particleIndex = 0;
    for (double weight : weights) {
      results.child(Runner.MONITORING_FOLDER).getTabularWriter(weightsFileName).write(
          Pair.of(annealingParameterColumn, temperature),
          Pair.of(particleColumn, particleIndex),
          Pair.of(weightColumn, weight)
      );
      particleIndex++;
    }
  }

  @Override
  protected void recordAncestry(int iteration, List<Integer> ancestors, double temperature)
  {
    int particleIndex = 0;
    for (int ancestor : ancestors)
    {
      results.child(Runner.MONITORING_FOLDER).getTabularWriter(ancestryFileName).write(
          Pair.of(iterationColumn, iteration),
          Pair.of(annealingParameterColumn, temperature),
          Pair.of(particleColumn, particleIndex),
          Pair.of(ancestorColumn, ancestor)
      );
      particleIndex++;
    }
  }

  @Override
  protected void recordPropagationStatistics(int iteration, double nextTemp, double ess, double logNorm) {
    results.child(Runner.MONITORING_FOLDER).getTabularWriter(propagationFileName).write(
        Pair.of(iterationColumn, iteration),
        Pair.of(annealingParameterColumn, nextTemp),
        Pair.of(essColumn, ess),
        Pair.of(logNormalizationColumn, logNorm)
    );
    super.recordPropagationStatistics(iteration, nextTemp, ess, logNorm);
  }

  @Override
  protected void recordResamplingStatistics(int iteration, double temperature, double logNormalization) {
    results.child(Runner.MONITORING_FOLDER).getTabularWriter(resamplingFileName).write(
        Pair.of(iterationColumn, iteration),
        Pair.of(annealingParameterColumn, temperature),
        Pair.of(logNormalizationColumn, logNormalization)
    );
    super.recordResamplingStatistics(iteration, temperature, logNormalization);
  }
}

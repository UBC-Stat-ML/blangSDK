package blang.engines.internals.factories;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.Random;
import bayonet.smc.ParticlePopulation;
import blang.engines.AdaptiveJarzynski;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefIO;
import briefj.BriefParallel;

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

  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    // create approx
    ParticlePopulation<SampledModel> approximation = getApproximation(model);
    
    // write Z estimate
    double logNormEstimate = approximation.logNormEstimate();
    log("Log normalization constant estimate: " + logNormEstimate);
    BriefIO.write(results.getFileInResultFolder(Runner.LOG_NORM_ESTIMATE), "" + logNormEstimate);
    
    // resample & rejuvenate the last iteration to simplify processing downstream
    if (!isUniform(approximation)) // could happen if there were zero-weight particles in last round
      approximation = approximation.resample(random, resamplingScheme);
    rejuvenate(parallelRandomStreams, approximation);
    
    // write samples
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    BlangTidySerializer densitySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    int particleIndex = 0;
    for (SampledModel model : approximation.particles)  
    {
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", particleIndex)); 
      densitySerializer.serialize(model.logDensity(), "logDensity", Pair.of("sample", particleIndex));
      particleIndex++;
    }
  }
  
  private boolean isUniform(ParticlePopulation<?> pop)
  {
    for (int i = 0; i < pop.nParticles(); i++) 
      if (pop.getNormalizedWeight(i) != 1.0 / ((double) pop.nParticles()))
        return false;
    return true;
  }
  
  private void rejuvenate(Random [] randoms, final ParticlePopulation<SampledModel> finalPopulation)
  {
    if (nFinalRejuvenations == 0) 
      return;
    log("Final rejuvenation started");
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
}

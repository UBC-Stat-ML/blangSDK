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
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefIO;
import briefj.BriefParallel;

/**
 * Sequential Change of Measure implementation.
 */
public class SCM extends AdaptiveJarzynski implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results = new ExperimentResults();
  
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
    System.out.println("Normalization constant estimate: " + logNormEstimate);
    BriefIO.write(results.getFileInResultFolder("logNormEstimate.txt"), "" + logNormEstimate);
    
    // resample & rejuvenate the last iteration to simplify processing downstream
    approximation = approximation.resample(random, resamplingScheme);
    rejuvenate(parallelRandomStreams, approximation);
    
    // write samples
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child("samples")); 
    int particleIndex = 0;
    for (SampledModel model : approximation.particles)  
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", particleIndex++)); 
  }
  
  private void rejuvenate(Random [] randoms, final ParticlePopulation<SampledModel> finalPopulation)
  {
    if (nFinalRejuvenations == 0) 
      return;
    System.out.println("Final rejuvenation started");
    deepCopyParticles(finalPopulation);
    BriefParallel.process(nParticles, nThreads.available, particleIndex ->
    {
      Random random = randoms[particleIndex];
      for (int i = 0; i < nFinalRejuvenations; i++)
        finalPopulation.particles.get(particleIndex).posteriorSamplingStep_deterministicScanAndShuffle(random);
    });
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    // TODO: may want to check forward simulators ok
    return;
  }
}

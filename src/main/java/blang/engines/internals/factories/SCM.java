package blang.engines.internals.factories;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.smc.ParticlePopulation;
import blang.engines.AdaptiveJarzynski;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.io.BlangTidySerializer;
import blang.runtime.SampledModel;
import blang.runtime.internals.model2kernel.ChangeOfMeasureKernel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefIO;

/**
 * Sequential Change of Measure implementation.
 */
public class SCM extends AdaptiveJarzynski<SampledModel> implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results = new ExperimentResults();
  
  ChangeOfMeasureKernel kernel;
  
  @Override
  public void setSampledModel(SampledModel model) 
  { 
    this.kernel = new ChangeOfMeasureKernel(model);
  }

  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    // create approx
    ParticlePopulation<SampledModel> approximation = getApproximation(kernel);
    
    // resample for now the last iteration to simplify processing downstream
    approximation = approximation.resample(random, resamplingScheme);
    
    // write Z estimate
    double logNormEstimate = approximation.logNormEstimate();
    System.out.println("Normalization constant estimate: " + logNormEstimate);
    BriefIO.write(results.getFileInResultFolder("logNormEstimate.txt"), "" + logNormEstimate);
    
    // write samples
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child("samples")); 
    int particleIndex = 0;
    for (SampledModel model : approximation.particles)  
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", particleIndex++)); 
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    // TODO: may want to check forward simulators ok
    return;
  }
}

package blang.engines;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.smc.ParticlePopulation;
import blang.algo.AdaptiveJarzynski;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.runtime.BlangTidySerializer;
import blang.runtime.ChangeOfMeasureKernel;
import blang.runtime.SampledModel;
import blang.runtime.objectgraph.GraphAnalysis;

/**
 * Sequential Change of Measure implementation.
 */
public class SCM extends AdaptiveJarzynski<SampledModel> implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results;
  
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

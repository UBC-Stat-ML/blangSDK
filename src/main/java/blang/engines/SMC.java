package blang.engines;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.smc.ParticlePopulation;
import blang.algo.ChangeOfMeasureSMC;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.runtime.BlangTidySerializer;
import blang.runtime.ChangeOfMeasureKernel;
import blang.runtime.SampledModel;

public class SMC extends ChangeOfMeasureSMC<SampledModel> implements PosteriorInferenceEngine
{
  @GlobalArg ExperimentResults results;
  
  @Override
  public void setSampledModel(SampledModel model) 
  { 
    setKernels(new ChangeOfMeasureKernel(model));
  }

  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    // create approx
    ParticlePopulation<SampledModel> approximation = getApproximation();
    
    // resample for now the last iteration to simplify processing downstream
    approximation = approximation.resample(random, resamplingScheme);
    
    // write samples
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results);
    int i = 0;
    for (SampledModel model : approximation.particles)  
      model.getSampleWriter(tidySerializer).write(Pair.of("sample", i++)); 
  }
}

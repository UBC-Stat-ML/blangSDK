package blang.engines;

import org.eclipse.xtext.xbase.lib.Pair;

import bayonet.distributions.Random;
import blang.algo.ParallelTempering;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.runtime.BlangTidySerializer;
import blang.runtime.ChangeOfMeasureKernel;
import blang.runtime.SampledModel;
import blang.runtime.objectgraph.GraphAnalysis;

public class PT extends ParallelTempering<SampledModel> implements PosteriorInferenceEngine  
{
  @GlobalArg ExperimentResults results;
  
  @Arg @DefaultValue("10_000")
  public int nScans = 10_000;
  
  @Arg         @DefaultValue("10")
  public int nPassesPerScan = 10;
  
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  @Override
  public void setSampledModel(SampledModel model) 
  {
    initialize(new ChangeOfMeasureKernel(model));
  }

  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child("samples")); 
    for (int iter = 0; iter < nScans; iter++)
    {
      moveKernel(random, nScans);
      getTargetState().getSampleWriter(tidySerializer).write(Pair.of("sample", iter));
      swapKernel(random);
    }
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    // TODO: may want to check forward simulators ok
    return;
  }
}

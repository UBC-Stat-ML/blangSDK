package blang.validation;

import java.util.List;
import java.util.function.Function;

import org.junit.Assert;

import bayonet.distributions.Random;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.mcmc.Sampler;
import blang.runtime.SampledModel;

public class DeterminismTest 
{
  @Arg       @DefaultValue("10")
  public int nIndependentSamples = 10;
  
  @Arg             @DefaultValue("10")
  public int nPosteriorSamplesPerIndep = 10;
  
  public void check(Instance<?> instance)
  {
    System.out.print("Running DeterminismTest on model " + instance.model.getClass().getSimpleName());
    for (Class<? extends Sampler> currentSamplerType : instance.samplerTypes())
    {
      System.out.print(" [" + currentSamplerType.getSimpleName() + "]");
      SampledModel sampledModel = instance.restrictedSampledModel(currentSamplerType);
      checkDeterministic(sampledModel, instance.testFunctions, false);
      checkDeterministic(sampledModel, instance.testFunctions, true);
    }
    System.out.println();
  }
  
  private <M> void checkDeterministic(SampledModel sampledModel, Function<M, Double>[] testFunctions, boolean usePosterior) 
  {

    List<List<Double>> 
      list1 = ExactInvarianceTest.sample(new Random(1), sampledModel, testFunctions, usePosterior, nIndependentSamples, nPosteriorSamplesPerIndep),
      list2 = ExactInvarianceTest.sample(new Random(1), sampledModel, testFunctions, usePosterior, nIndependentSamples, nPosteriorSamplesPerIndep);
    Assert.assertTrue(
        "Problem with model " + sampledModel.model.getClass().getSimpleName() + ": " +
        (usePosterior ? 
            "Posterior simulation should be deterministic given a random seed. "
            + "Problematic kernel: " + sampledModel.getPosteriorInvariantSamplers().get(0).getClass().getSimpleName() :
            "Forward simulation should be deterministic given a random seed.") + "\n" +
        list1.toString() + "\nvs\n" + list2.toString(), 
        list1.equals(list2));
  }
}

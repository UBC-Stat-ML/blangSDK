package blang.validation;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.commons.math3.stat.inference.TestUtils;

import com.google.common.primitives.Doubles;

import bayonet.distributions.Random;
import blang.core.Model;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.Implementations;
import blang.mcmc.Sampler;
import blang.mcmc.internals.BuiltSamplers;
import blang.mcmc.internals.SamplerBuilder;
import blang.runtime.Observations;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefCollections;

public class ExactTest
{
  @Arg        @DefaultValue("1")
  Random random = new Random(1);
  
  @Arg @DefaultValue("TTest")
  Test test     = new TTest();
  
  @Arg       @DefaultValue("1000")
  int nIndependentSamples = 1000;
  
  @Arg             @DefaultValue("10")
  int nPosteriorSamplesPerIndep = 10;
  
  private List<TestResult> results = new ArrayList<>();
  
  public List<Double> pValues()
  {
    return results.stream().map(result -> test.pValue(result.fStats, result.fpStats)).collect(Collectors.toList());
  }
  
  public <M extends Model> void addTest(M model, Function<M, Double> testFunction) 
  {
    GraphAnalysis analysis = new GraphAnalysis(model, new Observations());
    BuiltSamplers kernels = SamplerBuilder.build(analysis);
    for (int samplerIndex = 0; samplerIndex < kernels.list.size(); samplerIndex++)
    {
      BuiltSamplers currentKernel = kernels.restrict(samplerIndex);
      SampledModel sampledModel = new SampledModel(analysis, currentKernel, random);
      
      List<Double> forwardSamples          = sample(sampledModel, model, testFunction, false);
      List<Double> forwardPosteriorSamples = sample(sampledModel, model, testFunction, true);
      
      results.add(new TestResult(model, testFunction, BriefCollections.pick(currentKernel.list), forwardSamples, forwardPosteriorSamples));
    }
  }
  
  public static class TestResult
  {
    public final Model model;
    public final Function<?,Double> testFunction;
    public final Sampler sampler;
    public final List<Double> fStats, fpStats;
    public TestResult(Model model, Function<?, Double> testFunction, Sampler sampler, List<Double> fStats,
        List<Double> fpStats) {
      super();
      this.model = model;
      this.testFunction = testFunction;
      this.sampler = sampler;
      this.fStats = fStats;
      this.fpStats = fpStats;
    }

  }
  
  private <M> List<Double> sample(SampledModel sampledModel, M model, Function<M, Double> testFunction, boolean withPosterior) 
  {
    List<Double> result = new ArrayList<Double>();
    for (int i = 0; i < nIndependentSamples; i++)
    {
      sampledModel.forwardSample(random);
      if (withPosterior)
        for (int j = 0; j < nPosteriorSamplesPerIndep; j++)
          sampledModel.posteriorSamplingStep_deterministicScanAndShuffle(random);
      result.add(testFunction.apply(model));
    }
    return result;
  }

  @Implementations({TTest.class})
  public static interface Test
  {
    public double pValue(List<Double> sample1, List<Double> sample2);
  }
  
  public static class TTest implements Test
  {
    /**
     * 
     */
    @Override
    public double pValue(List<Double> sample1, List<Double> sample2)
    {
      return TestUtils.tTest(Doubles.toArray(sample1), Doubles.toArray(sample2));
    }
    
    /**
     * 
     */
    @Override
    public String toString() { return "TTest"; }
  }

  

}

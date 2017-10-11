package blang.validation;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
import org.apache.commons.math3.stat.inference.TestUtils;
import org.junit.Assert;

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
  
  @Arg      @DefaultValue("0.005")
  double familyWiseError = 0.005;
  
  private List<TestResult> results = new ArrayList<>();

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
  
  public double correctedPValue()
  {
    if (results.isEmpty())
      throw new RuntimeException("Need to add tests first.");
    return 1.0 - Math.pow(1.0 - familyWiseError, 1.0/((double) results.size()));
  }
  
  public List<TestResult> failedTests()
  {
    // compute via Sidak since tests are independent by construction
    List<TestResult> offenders = new ArrayList<>();
    double corrected = correctedPValue();
    for (TestResult result : results)
      if (result.pValue < corrected)
        offenders.add(result);
    return offenders;
  }
  
  public void check()
  {
    List<TestResult> failedTests = failedTests();
    if (!failedTests.isEmpty())
      Assert.fail("Some test(s) failed:\n" + format(failedTests));
    else
      System.out.println("All tests passed:\n" + format(results));
  }
  
  public static String format(List<TestResult> failedTests) 
  {
    return failedTests.stream().map(t -> t.toString()).collect(Collectors.joining("\n"));
  }

  public class TestResult
  {
    public final Model model;
    public final Function<?,Double> testFunction;
    public final Sampler sampler;
    public final List<Double> fStats, fpStats;
    public final SummaryStatistics fSummary, fpSummary;
    public final double pValue;
    public TestResult(
        Model model, 
        Function<?, Double> testFunction, 
        Sampler sampler, List<Double> fStats,
        List<Double> fpStats) 
    {
      super();
      this.model = model;
      this.testFunction = testFunction;
      this.sampler = sampler;
      this.fStats = fStats;
      this.fpStats = fpStats;
      this.pValue = test.pValue(fStats, fpStats);
      if (Double.isNaN(pValue))
        throw new RuntimeException();
      this.fSummary  = new SummaryStatistics(); for (double v : fStats)  fSummary.addValue(v);
      this.fpSummary = new SummaryStatistics(); for (double v : fpStats) fpSummary.addValue(v); 
    }
    @Override
    public String toString()
    {
      return "" + model.getClass().getSimpleName() + '\t' + testFunction.getClass().getSimpleName() + '\t' + pValue + '\t' 
          + fSummary.getMean()  + "(" + fSummary.getStandardDeviation() + ")" + '\t'
          + fpSummary.getMean() + "(" + fpSummary.getStandardDeviation() + ")"; 
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

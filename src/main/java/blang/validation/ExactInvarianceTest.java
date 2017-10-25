package blang.validation;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
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
import blang.mcmc.internals.SamplerBuilderOptions;
import blang.runtime.Observations;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefCollections;

public class ExactInvarianceTest
{
  @Arg        @DefaultValue("1")
  public Random random = new Random(1);
  
  @Arg @DefaultValue("KSTest")
  public Test test     = new KSTest();
  
  @Arg       @DefaultValue("10_000")
  public int nIndependentSamples = 10_000;
  
  @Arg             @DefaultValue("10")
  public int nPosteriorSamplesPerIndep = 10;
  
  @Arg      @DefaultValue("0.005")
  public double familyWiseError = 0.005;
  
  private final boolean justComputeNumberOfTests;
  
  public ExactInvarianceTest(boolean justComputeNumberOfTests) 
  {
    this.justComputeNumberOfTests = justComputeNumberOfTests;
  }
  
  public ExactInvarianceTest() 
  {
    this(false);
  }

  public List<TestResult> results = new ArrayList<>();
  private int nTests = 0;
  
  public <M extends Model> void add(
      M model, 
      @SuppressWarnings("unchecked") Function<M, Double> ... testFunctions) 
  {
    add(model, new SamplerBuilderOptions(), testFunctions);
  }
  
  public <M extends Model> void add(
      M model, 
      SamplerBuilderOptions samplerOptions,
      @SuppressWarnings("unchecked") Function<M, Double> ... testFunctions) 
  {
    if (!justComputeNumberOfTests)
      System.out.print("Running ExactInvarianceTest on model " + model.getClass().getSimpleName());
    GraphAnalysis analysis = new GraphAnalysis(model, new Observations());
    BuiltSamplers kernels = SamplerBuilder.build(analysis, samplerOptions);
    if (kernels.list.isEmpty())
      throw new RuntimeException("No kernels produced by model to be tested");
    Set<Class<? extends Sampler>> samplerTypes = kernels.list.stream().map(s -> s.getClass()).collect(Collectors.toSet());
    for (Class<? extends Sampler> currentSamplerType : samplerTypes)
    {
      if (!justComputeNumberOfTests)
        System.out.print(" [" + currentSamplerType.getSimpleName() + "] ");
      BuiltSamplers currentKernel = kernels.restrict(s -> s.getClass() == currentSamplerType);
      SampledModel sampledModel = new SampledModel(analysis, currentKernel, random);
      
      List<List<Double>> forwardSamples          = justComputeNumberOfTests ? null : sample(sampledModel, model, testFunctions, false);
      List<List<Double>> forwardPosteriorSamples = justComputeNumberOfTests ? null : sample(sampledModel, model, testFunctions, true);
      
      for (int testIndex = 0; testIndex < testFunctions.length; testIndex++)
      {
        nTests++;
        if (!justComputeNumberOfTests)
          results.add(new TestResult(model, testFunctions[testIndex], BriefCollections.pick(currentKernel.list), forwardSamples.get(testIndex), forwardPosteriorSamples.get(testIndex)));
      }
    }
    if (!justComputeNumberOfTests)
      System.out.println();
  }
  
  public double correctedPValue()
  {
    if (nTests == 0)
      throw new RuntimeException("Need to add tests first.");
    // Note: there can be dependence between tests when using several test functions
    return familyWiseError / ((double) nTests);
  }
  
  public List<TestResult> failedTests()
  {
    return failedTests(correctedPValue());
  }
  
  public List<TestResult> failedTests(double threshold)
  {
    List<TestResult> offenders = new ArrayList<>();
    for (TestResult result : results)
      if (result.pValue < threshold)
        offenders.add(result);
    return offenders;
  }
  
  public int nTests() 
  {
    return nTests;
  }
  
  public void check()
  {
    check(correctedPValue());
  }
  
  public void check(double threshold) 
  {
    List<TestResult> failedTests = failedTests(threshold);
    if (!failedTests.isEmpty())
      Assert.fail("Some test(s) failed:\n" + format(failedTests));
    else
      System.out.println("All tests passed:\n" + format(results));
  }
  
  public static String format(List<TestResult> tests) 
  {
    Collections.sort(tests, Comparator.comparing(result -> result.pValue));
    return tests.stream().map(t -> t.toString()).collect(Collectors.joining("\n"));
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
      return "" + model.getClass().getSimpleName() + '\t' + sampler.getClass().getSimpleName() + "\t" + testFunction.getClass().getSimpleName() + '\t' + pValue + '\t' 
          + fSummary.getMean()  + "(" + fSummary.getStandardDeviation() /Math.sqrt(fSummary.getN()) + ")" + '\t'
          + fpSummary.getMean() + "(" + fpSummary.getStandardDeviation()/Math.sqrt(fpSummary.getN()) + ")"; 
    }
  }
  
  private <M> List<List<Double>> sample(SampledModel sampledModel, M model, Function<M, Double> [] testFunctions, boolean withPosterior) 
  {
    List<List<Double>> results = new ArrayList<>();
    for (Function<M, Double> testFunction : testFunctions)
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
      results.add(result);
    }
    return results;
  }

  @Implementations({TTest.class, KSTest.class})
  public static interface Test
  {
    public double pValue(List<Double> sample1, List<Double> sample2);
  }
  
  public static class KSTest implements Test
  {
    /**
     * 
     */
    @Override
    public double pValue(List<Double> sample1, List<Double> sample2)
    {
      return TestUtils.kolmogorovSmirnovTest(Doubles.toArray(sample1), Doubles.toArray(sample2));
    }
    
    /**
     * 
     */
    @Override
    public String toString() { return "KSTest"; }   
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

package blang.validation;

import java.io.File;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.commons.math3.stat.descriptive.SummaryStatistics;
import org.apache.commons.math3.stat.inference.TestUtils;
import org.junit.Assert;

import com.google.common.base.Joiner;
import com.google.common.collect.HashBasedTable;
import com.google.common.collect.Table;
import com.google.common.primitives.Doubles;

import bayonet.distributions.Random;
import blang.core.Model;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.Implementations;
import blang.mcmc.Sampler;
import blang.runtime.SampledModel;
import blang.validation.internals.Helpers;
import briefj.BriefIO;

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
  
  public <M extends Model> void add(M model, Function<M, Double> ... testFunctions) {
    add(new Instance<M>(model, testFunctions));
  }
  
  @SuppressWarnings("unchecked")
  public void add(Instance<?> instance) 
  {
    if (!justComputeNumberOfTests)
      System.out.print("Running ExactInvarianceTest on model " + instance.model.getClass().getSimpleName());
    
    Set<Class<? extends Sampler>> restrictions = instance.samplerTypes();
    if (restrictions.size() > 1)
      restrictions.add(null); // also run all samplers in conjunction (only useful if more than one sampler type defined)
    
    for (Class<? extends Sampler> currentSamplerType : restrictions)
    {
      if (!justComputeNumberOfTests)
        System.out.print(" [" + (currentSamplerType == null ? "ALL" : currentSamplerType.getSimpleName()) + "]");
      
      SampledModel sampledModel = currentSamplerType == null ?
          instance.sampledModel :
          instance.restrictedSampledModel(currentSamplerType);
      
      SummaryStatistics moveStats = new SummaryStatistics();
      Table<Integer, Function<?,?>, Double> forwardSamples          = justComputeNumberOfTests ? null : sample(random, sampledModel, instance.testFunctions, false, nIndependentSamples, nPosteriorSamplesPerIndep, null);
      Table<Integer, Function<?,?>, Double> forwardPosteriorSamples = justComputeNumberOfTests ? null : sample(random, sampledModel, instance.testFunctions, true, nIndependentSamples, nPosteriorSamplesPerIndep, moveStats);
      
      for (@SuppressWarnings("rawtypes") Function testFunction : instance.testFunctions)
      {
        nTests++;
        if (!justComputeNumberOfTests)
          results.add(new TestResult(instance.model, testFunction, currentSamplerType, forwardSamples.column(testFunction), forwardPosteriorSamples.column(testFunction), moveStats.getMean()));
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
    {
      File cwd = Paths.get("").toAbsolutePath().toFile();
      cwd = new File(cwd, "failed-test-info-" + System.currentTimeMillis());
      cwd.mkdir();
      for (TestResult failedTest : failedTests)
        failedTest.dumpInto(cwd);
      Assert.fail("Some test(s) failed (samples saved in " + cwd.getAbsolutePath() + "):\n" + format(failedTests));
    }
    else
      System.out.println("All ExactInvariance tests passed:\n" + format(results));
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
    public final String samplerDescription;
    public final List<Double> fStats, fpStats;
    public final SummaryStatistics fSummary, fpSummary;
    public final double pValue;
    public final double movedFraction;
    public TestResult(
        Model model, 
        Function<?, Double> testFunction, 
        Class<? extends Sampler> samplerType, Map<Integer, Double> _fStats,
        Map<Integer, Double> _fpStats,
        double movedFraction) 
    {
      super();
      this.model = model;
      this.testFunction = testFunction;
      this.samplerDescription = samplerType == null ? "ALL" : samplerType.getSimpleName();
      this.fStats = map2list(_fStats);
      this.fpStats = map2list(_fpStats);
      this.pValue = test.pValue(fStats, fpStats);
      if (Double.isNaN(pValue))
        throw new RuntimeException();
      this.fSummary  = new SummaryStatistics(); for (double v : fStats)  fSummary.addValue(v);
      this.fpSummary = new SummaryStatistics(); for (double v : fpStats) fpSummary.addValue(v); 
      this.movedFraction = movedFraction;
    }
    
    private List<Double> map2list(Map<Integer, Double> map) 
    {
      List<Double> result = new ArrayList<>();
      for (int i = 0; i < map.size(); i++)
        if (map.get(i) == null)
          throw new RuntimeException();
        else
          result.add(map.get(i));
      return result;
    }

    public void dumpInto(File directory)
    {
      String baseName = model.getClass().getSimpleName() + "." + samplerDescription + "." + testFunction.getClass().getSimpleName().replace("/", "-");
      String fFile = baseName + ".fData.csv";
      String fpFile = baseName + ".fpData.csv";
      
      BriefIO.write(new File(directory, baseName + ".pValue.txt"), "" + pValue);
      BriefIO.write(new File(directory, fFile), Joiner.on("\n").join(fStats));
      BriefIO.write(new File(directory, fpFile), Joiner.on("\n").join(fpStats));
      Helpers.generateQQPlotScript(fFile, fpFile, baseName + ".plot.pdf", new File(directory, "qqPlotScript.r"));
    }
    
    @Override
    public String toString()
    {
      return "" + model.getClass().getSimpleName() + " \t" + samplerDescription + " \t" + testFunction.getClass().getSimpleName() + " \t" + pValue + " \t" 
          + fSummary.getMean()  + "(" + fSummary.getStandardDeviation() /Math.sqrt(fSummary.getN()) + ")" + " \t"
          + fpSummary.getMean() + "(" + fpSummary.getStandardDeviation()/Math.sqrt(fpSummary.getN()) + ")" + " \t" + movedFraction ; 
    }
  }
  
  @SuppressWarnings("unchecked")
  public static <M> Table<Integer, Function<?,?>, Double> sample( 
      Random random, 
      SampledModel sampledModel, 
      Function<M, Double> [] testFunctions, 
      boolean withPosterior,
      int nIndependentSamples,
      int nPosteriorSamplesPerIndep,
      SummaryStatistics movedStats) 
  {
    sampledModel = sampledModel.duplicate(); // Important to duplicate when checking determinism (sampledModel keeps track of sampler index)
    Table<Integer, Function<?,?>, Double> results = HashBasedTable.create();

    for (int i = 0; i < nIndependentSamples; i++)
    {
      sampledModel.forwardSample(random, true);
      Map<Function<M,Double>,Double> before = withPosterior ? eval((M) sampledModel.model, testFunctions) : null;
      if (withPosterior)
        for (int j = 0; j < nPosteriorSamplesPerIndep; j++)
          sampledModel.posteriorSamplingStep(random);
      
      Map<Function<M,Double>,Double> after = eval((M) sampledModel.model, testFunctions);
      if (withPosterior)
        movedStats.addValue(after.equals(before) ? 0.0 : 1.0);
      results.row(i).putAll(after);
    }
    return results;
  }
  
  private static <M> Map<Function<M,Double>,Double> eval(M model, Function<M, Double> [] testFunctions)
  {
    Map<Function<M,Double>,Double> result = new LinkedHashMap<Function<M,Double>, Double>();
    for (Function<M, Double> f : testFunctions)
      result.put(f, f.apply(model));
    return result;
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

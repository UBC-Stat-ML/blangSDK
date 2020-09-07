package blang.runtime;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import bayonet.distributions.Random;
import bayonet.math.NumericalUtils;

import java.util.Set;
import java.util.stream.Collectors;

import blang.core.AnnealedFactor;
import blang.core.Factor;
import blang.core.ForwardSimulator;
import blang.core.LogScaleFactor;
import blang.core.Model;
import blang.core.Param;
import blang.inits.experiments.tabwriters.TidySerializer;
import blang.mcmc.Sampler;
import blang.mcmc.internals.BuiltSamplers;
import blang.mcmc.internals.ExponentiatedFactor;
import blang.mcmc.internals.SamplerBuilder;
import blang.runtime.internals.objectgraph.AnnealingStructure;
import blang.runtime.internals.objectgraph.DeepCloner;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.runtime.internals.objectgraph.Node;
import blang.runtime.internals.objectgraph.StaticUtils;
import blang.types.internals.RealScalar;
import briefj.BriefLists;
import briefj.BriefLog;
import briefj.ReflexionUtils;

public class SampledModel 
{
  public final Model model;
  public final boolean annealSupport;
  private final List<Sampler> posteriorInvariantSamplers;

  private List<ForwardSimulator> forwardSamplers;
  private final RealScalar _annealingExponent; // can be null when called from GraphAnalysis.noAnnealer()
  
  //// Various caches to make it quick to compute the global density
  
  /*
   * Factors that can be updated lazily. Contains those in (1) AnnealingStructure.fixedLogScaleFactors 
   * (enclosing them in a trivial ExponentiatedFactor if necessary)
   * and (2) AnnealingStructure.exponentiatedFactors.
   * 
   * Excludes otherAnnealedFactors which need to be all computed explicitly at all times.
   */
  private final List<ExponentiatedFactor> sparseUpdateFactors; 
  
  /*
   * Indices for (1) and (2) described above
   */
  private final ArrayList<Integer> sparseUpdateFixedIndices = new ArrayList<>();    // (1)
  private final ArrayList<Integer> sparseUpdateAnnealedIndices = new ArrayList<>(); // (2)
  
  // TODO: make sure the index-based data structures are shallowly cloned
  // sampler index -> factor indices (using array since inner might have lots of small arrays)
  private final int [][] 
      sampler2sparseUpdateFixed,    // (1)
      sampler2sparseUpdateAnnealed; // (2)
  
  private final double [] caches;
  private double sumPreannealedFiniteDensities, sumFixedDensities;
  private int nOutOfSupport;
  private boolean annealedOutOfSupportDetected = false;
  
  public boolean annealedOutOfSupportDetected() { return annealedOutOfSupportDetected; }
  
  /*
   * Those need to be recomputed each time
   */
  private final List<AnnealedFactor> otherAnnealedFactors;
  
  public int nOtherAnnealedFactors() { return otherAnnealedFactors.size(); }
  
  private List<Integer> currentSamplingOrder = null;
  private int currentPosition = -1;
  
  public final Map<String, Object> objectsToOutput;
  
  
  public SampledModel(Model model) 
  {
    this(new GraphAnalysis(model));
  }
  
  public SampledModel(GraphAnalysis graphAnalysis)
  {
    this(graphAnalysis, SamplerBuilder.build(graphAnalysis));
  }
  
  public SampledModel(GraphAnalysis graphAnalysis, BuiltSamplers samplers)
  {
    this(graphAnalysis, samplers, true, true, new Random(1)); 
  }
  
  public SampledModel(
      GraphAnalysis graphAnalysis, 
      BuiltSamplers samplers, 
      boolean createLikehoodAnnealer,
      boolean createForwardSamplers,
      Random forwardInit) 
  {
    this.annealSupport = graphAnalysis.annealSupport;
    boolean initUsingForward = forwardInit != null;
    if (!createForwardSamplers && initUsingForward)
      throw new RuntimeException();
    this.model = graphAnalysis.model;
    this.posteriorInvariantSamplers = samplers.list;
    this.forwardSamplers = createForwardSamplers ? graphAnalysis.createForwardSimulator() : null;
    AnnealingStructure annealingStructure = createLikehoodAnnealer ? graphAnalysis.createLikelihoodAnnealer() : graphAnalysis.noAnnealer();
    this._annealingExponent = annealingStructure.annealingParameter;
    
    otherAnnealedFactors = annealingStructure.otherAnnealedFactors;
    
    sparseUpdateFactors = initSparseUpdateFactors(annealingStructure, graphAnalysis.treatNaNAsNegativeInfinity, annealSupport);
    caches = new double[sparseUpdateFactors.size()];
    
    sampler2sparseUpdateAnnealed = new int[samplers.list.size()][];
    sampler2sparseUpdateFixed = new int[samplers.list.size()][];
    initSampler2FactorIndices(graphAnalysis, samplers, annealingStructure);
    
    Set<ExponentiatedFactor> exponentiatedFactorsSet = new HashSet<>(annealingStructure.exponentiatedFactors);
    for (int i = 0; i < sparseUpdateFactors.size(); i++)
      (exponentiatedFactorsSet.contains(sparseUpdateFactors.get(i)) ? sparseUpdateAnnealedIndices : sparseUpdateFixedIndices).add(i);
    
    this.objectsToOutput = new LinkedHashMap<String, Object>();
    for (Field f : StaticUtils.getDeclaredFields(model.getClass())) 
      if (f.getAnnotation(Param.class) == null) // Note: Runner will then exclude things fully observed (done there to allow also explicit exclusions first)
        objectsToOutput.put(f.getName(), ReflexionUtils.getFieldValue(f, model));
    
    if (initUsingForward)
      forwardSample(forwardInit, true);  
    updateAll(); // need it again in case we are not forwardSampling (TODO: refactor)
  }
  
  /**
   * A simplified SampledModel without annealing nor forward sampling
   */
  public static SampledModel stripped(GraphAnalysis graphAnalysis, BuiltSamplers samplers)
  {
    return new SampledModel(graphAnalysis, samplers, false, false, null); 
  }
  
  public int nPosteriorSamplers()
  {
    return posteriorInvariantSamplers.size();
  }
  
  public static boolean check = false;
  
  public double logDensity()
  {
    final double exponentValue = getExponent(); 
    
    final double result = !annealSupport && nOutOfSupport > 0 ?
      Double.NEGATIVE_INFINITY
      :
      sumOtherAnnealed() 
        + sumFixedDensities 
        + exponentValue * sumPreannealedFiniteDensities
        // ?: to avoid 0 * -INF
        + (nOutOfSupport == 0 ? 0.0 : nOutOfSupport * ExponentiatedFactor.annealedMinusInfinity(exponentValue));
       
    if (check) check(result);
    return result;
  }
  
  private void check(double expected) 
  {
    double sum = 0.0;
    for (ExponentiatedFactor f : sparseUpdateFactors)
      sum += f.logDensity();
    for (LogScaleFactor f : otherAnnealedFactors)
      sum += f.logDensity();
    if (expected == Double.NEGATIVE_INFINITY && sum == Double.NEGATIVE_INFINITY)
      return;
    NumericalUtils.checkIsClose(expected, sum);
  }
  
  public double logDensity(double temperingParameter) 
  {
    final double previousValue = getExponent();
    setExponent(temperingParameter);
    final double result = logDensity();
    setExponent(previousValue);
    return result;
  }
  
  public double logDensityRatio(double temperature, double nextTemperature) 
  {
    double num = logDensity(nextTemperature);
    double denom = logDensity(temperature);
    if (num == Double.NEGATIVE_INFINITY && denom == Double.NEGATIVE_INFINITY)
      throw new RuntimeException(INVALID_LOG_RATIO);
    return num - denom;
  }
  static final String INVALID_LOG_RATIO = "Invalid logDensity ratio (0/0): this could be caused by a generate(rand){..} block not faithful with its laws{..} block.";
  
  public double preAnnealedLogLikelihood()
  {
    return sumPreannealedFiniteDensities;
  }

  public int nOutOfSupport() 
  {
    return nOutOfSupport;
  }
  
  public double sumOtherAnnealed()
  {
    double sum = 0.0;
    for (AnnealedFactor factor : otherAnnealedFactors)
      sum += factor.logDensity();
    return sum;
  }
  
  public SampledModel duplicate() 
  {
    return DeepCloner.deepClone(this);
  }
  
  public void posteriorSamplingStep(Random random, int kernelIndex)
  {
    posteriorInvariantSamplers.get(kernelIndex).execute(random);  
    update(kernelIndex);
  }
  
  public void posteriorSamplingScan(Random random) 
  {
    for (int i = 0; i < posteriorInvariantSamplers.size(); i++)
      posteriorSamplingStep(random);
  }
  
  /**
   * @param random
   * @param multiplier Can be used for performing the fraction of a scan, or many scans. 
   *  I.e. the number of steps will be floor(multiplyer * number of posterior invar moves)
   */
  public void posteriorSamplingScan(Random random, double multiplier)
  {
    int nSteps = (int) Math.floor(multiplier * posteriorInvariantSamplers.size());
    for (int i = 0; i < nSteps; i++)
      posteriorSamplingStep(random); 
  }
  
  public void posteriorSamplingStep(Random random)
  {
    if (posteriorInvariantSamplers.isEmpty()) 
    {
      BriefLog.warnOnce("no posterior sampler defined");
      return;
    }
    if (currentSamplingOrder == null)
      currentSamplingOrder = new ArrayList<>(BriefLists.integers(nPosteriorSamplers()).asList());
    if (currentPosition == -1)
    {
      Collections.shuffle(currentSamplingOrder, random);
      currentPosition = nPosteriorSamplers() - 1;
    }
    int samplerIndex = currentSamplingOrder.get(currentPosition--);
    posteriorSamplingStep(random, samplerIndex);
  }
  
  public void forwardSample(Random random, boolean force)
  {
    if (!force && sparseUpdateAnnealedIndices.size() > 0 && getExponent() != 0.0)
      throw new RuntimeException("Forward sampling only possible at temperature zero.");
    for (ForwardSimulator sampler : forwardSamplers) 
      sampler.generate(random); 
    updateAll();
  }
  
  /**
   * Performance optimization: once the forward simulator 
   * not needed, dropping it speeds up cloning. Useful for 
   * Change of Measure algorithms, but not for tempering algorithms.
   */
  public void dropForwardSimulator()
  {
    this.forwardSamplers = null;
  }
  
  public void setExponent(double value)
  {
    if (value == 1.0 && _annealingExponent == null)
      return; // nothing to do, if null we consider identical to 1.0
    _annealingExponent.set(value);
  }
  
  public double getExponent()
  {
    if (_annealingExponent == null) 
      return 1.0;
    return _annealingExponent.doubleValue(); 
  }
  
  public static class SampleWriter
  {
    final Map<String, Object> objectsToOutput;
    final TidySerializer serializer;
    public SampleWriter(Map<String, Object> objectsToOutput, TidySerializer serializer) 
    {
      this.objectsToOutput = objectsToOutput;
      this.serializer = serializer; 
    }
    public void write(@SuppressWarnings("unchecked") org.eclipse.xtext.xbase.lib.Pair<Object,Object> ... sampleContext)
    {
      for (Entry<String,Object> entry : objectsToOutput.entrySet()) 
        serializer.serialize(entry.getValue(), entry.getKey(), sampleContext);
    }
  }
  
  public SampleWriter getSampleWriter(TidySerializer serializer)
  {
    return new SampleWriter(objectsToOutput, serializer);
  }
  
  //// Cache management
  
  private void updateAll()
  {
    sumFixedDensities = 0.0;
    for (int fixedIndex : sparseUpdateFixedIndices)
    {
      double newCache = sparseUpdateFactors.get(fixedIndex).logDensity();
      sumFixedDensities += newCache;
      caches[fixedIndex] = newCache;
    }
    
    sumPreannealedFiniteDensities = 0.0;
    nOutOfSupport = 0;
    for (int annealedIndex : sparseUpdateAnnealedIndices)
    {
      double newPreAnnealedCache = sparseUpdateFactors.get(annealedIndex).enclosedLogDensity();
      caches[annealedIndex] = newPreAnnealedCache;
      
      if (newPreAnnealedCache == Double.NEGATIVE_INFINITY)
        nOutOfSupport++;
      else
        sumPreannealedFiniteDensities += newPreAnnealedCache;
    }
    if (nOutOfSupport > 0 && annealSupport)
      annealedOutOfSupportDetected = true;
  }
  
  private void update(int samplerIndex)
  {
    if (sumPreannealedFiniteDensities == Double.NEGATIVE_INFINITY || sumFixedDensities == Double.NEGATIVE_INFINITY)
    {
      System.err.println("WARNING: encountered unannealed probability zero configuration. This could happen infrequently due to numerical precision but could lead to performance problems if it happens frequently (e.g. due to determinism in likelihood). Try SCM or PT initialized with SCM and/or more particles");
      updateAll();
      return;
    }
    
    for (int fixedIndex : sampler2sparseUpdateFixed[samplerIndex])
    {
      double newCache = sparseUpdateFactors.get(fixedIndex).logDensity();
      sumFixedDensities += newCache - caches[fixedIndex];
      caches[fixedIndex] = newCache;
    }
    
    for (int annealedIndex : sampler2sparseUpdateAnnealed[samplerIndex])
    {
      {
        double oldPreAnneledCache = caches[annealedIndex];
        
        if (oldPreAnneledCache == Double.NEGATIVE_INFINITY)
          nOutOfSupport--;
        else
          sumPreannealedFiniteDensities -= oldPreAnneledCache;
      }
      
      {
        double newPreAnnealedCache = sparseUpdateFactors.get(annealedIndex).enclosedLogDensity();
        caches[annealedIndex] = newPreAnnealedCache;
        
        if (newPreAnnealedCache == Double.NEGATIVE_INFINITY) {
          if (annealSupport)
            annealedOutOfSupportDetected = true;
          nOutOfSupport++;
        } else
          sumPreannealedFiniteDensities += newPreAnnealedCache;
      }
    }
  }
  
  //// Utility methods setting up caches
  
  private void initSampler2FactorIndices(GraphAnalysis graphAnalysis, BuiltSamplers samplers, AnnealingStructure annealingStructure) 
  {
    Map<ExponentiatedFactor, Integer> factor2Index = factor2index(sparseUpdateFactors);
    Set<ExponentiatedFactor> annealedFactors = new HashSet<>(annealingStructure.exponentiatedFactors);
    for (int samplerIndex = 0; samplerIndex < samplers.list.size(); samplerIndex++)
    {
      Node sampledVariable = samplers.correspondingVariables.get(samplerIndex);
      List<? extends Factor> factors = 
          graphAnalysis.getConnectedFactor(sampledVariable).stream()
            .map(node -> node.object)
            .filter(factor -> factor instanceof LogScaleFactor)
            .collect(Collectors.toList());
      List<Integer> 
        annealedIndices = new ArrayList<>(),
        fixedIndices = new ArrayList<>();
      for (Factor f : factors) 
        if (!otherAnnealedFactors.contains(f))
          (annealedFactors.contains(f) ? annealedIndices : fixedIndices).add(factor2Index.get(f));
      sampler2sparseUpdateAnnealed[samplerIndex] = annealedIndices.stream().mapToInt(i->i).toArray();
      sampler2sparseUpdateFixed   [samplerIndex] = fixedIndices   .stream().mapToInt(i->i).toArray();
    }
  }

  private static Map<ExponentiatedFactor, Integer> factor2index(List<ExponentiatedFactor> factors) 
  {
    Map<ExponentiatedFactor, Integer> result = new IdentityHashMap<>();
    for (int i = 0; i < factors.size(); i++)
      result.put(factors.get(i), i);
    return result;
  }

  /**
   * Ignore factors that are not LogScaleFactor's (e.g. constraints), make sure everything else are AnnealedFactors.
   */
  private static List<ExponentiatedFactor> initSparseUpdateFactors(AnnealingStructure structure, boolean treatNaNAsNegativeInfinity, boolean annealSupport) 
  {
    ArrayList<ExponentiatedFactor> result = new ArrayList<>();
    result.addAll(structure.exponentiatedFactors);
    for (LogScaleFactor f : structure.fixedLogScaleFactors)
    {
      if (!(f instanceof ExponentiatedFactor))
        f = new ExponentiatedFactor(f, treatNaNAsNegativeInfinity, annealSupport);
      result.add((ExponentiatedFactor) f);
    }
    return result;
  }
  
  public List<Sampler> getPosteriorInvariantSamplers() 
  {
    return posteriorInvariantSamplers;
  }
}

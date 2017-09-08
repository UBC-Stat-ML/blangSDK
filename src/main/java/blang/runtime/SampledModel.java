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
import java.util.Random;
import java.util.Set;
import java.util.stream.Collectors;

import org.apache.commons.lang3.tuple.Pair;
import org.objenesis.strategy.StdInstantiatorStrategy;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryo.Kryo.DefaultInstantiatorStrategy;
import com.rits.cloning.Cloner;

import blang.algo.AnnealedParticle;
import blang.core.AnnealedFactor;
import blang.core.Factor;
import blang.core.ForwardSimulator;
import blang.core.LogScaleFactor;
import blang.core.Model;
import blang.core.Param;
import blang.inits.experiments.tabwriters.TidySerializer;
import blang.mcmc.BuiltSamplers;
import blang.mcmc.Sampler;
import blang.runtime.objectgraph.GraphAnalysis;
import blang.runtime.objectgraph.ObjectNode;
import briefj.BriefLists;
import briefj.ReflexionUtils;

public class SampledModel implements AnnealedParticle
{
  public final Model model;
  private final List<Sampler> posteriorInvariantSamplers;
  private List<ForwardSimulator> forwardSamplers;
  private double annealingExponent;
  
  //// Various caches to make it quick to compute the global density
  
  private final List<AnnealedFactor> factors; 
  
  // TODO: make sure the index-based data structures are shallowly cloned
  // sampler index -> factor indices (using array since inner might have lots of small arrays)
  private final int [][] 
      sampler2annealed, // for the factors undergoing annealing
      sampler2fixed;    // and the others ones
  
  private final ArrayList<Integer> allAnnealedFactors = new ArrayList<>();
  private final ArrayList<Integer> allFixedFactors = new ArrayList<>();
  
  private final double [] caches;
  private double sumPreannealedFiniteDensities, sumFixedDensities;
  private int nOutOfSupport;
  
  private List<Integer> currentSamplingOrder = null;
  private int currentPosition = -1;
  
  private final Map<String, Object> objectsToOutput;
  
  public SampledModel(GraphAnalysis graphAnalysis, BuiltSamplers samplers, Random initRandom) 
  {
    this.model = graphAnalysis.model;
    this.posteriorInvariantSamplers = samplers.list;
    this.forwardSamplers = graphAnalysis.createForwardSimulator();
    this.annealingExponent = 1.0;
    
    Pair<List<AnnealedFactor>, List<Factor>> annealingStructure = graphAnalysis.createLikelihoodAnnealer();
    factors = initFactors(annealingStructure);
    caches = new double[factors.size()];
    
    sampler2annealed = new int[samplers.list.size()][];
    sampler2fixed = new int[samplers.list.size()][];
    initSampler2FactorIndices(graphAnalysis, samplers, annealingStructure);
    
    Set<AnnealedFactor> annealedFactors = new HashSet<>(annealingStructure.getLeft());
    for (int i = 0; i < factors.size(); i++)
      (annealedFactors.contains(factors.get(i)) ? allAnnealedFactors : allFixedFactors).add(i);
    
    this.objectsToOutput = new LinkedHashMap<String, Object>();
    for (Field f : ReflexionUtils.getDeclaredFields(model.getClass(), true)) 
      if (f.getAnnotation(Param.class) == null) // TODO: filter out fully observed stuff too
        objectsToOutput.put(f.getName(), ReflexionUtils.getFieldValue(f, model));
    
    forwardSample(initRandom); 
  }
  
  public int nPosteriorSamplers()
  {
    return posteriorInvariantSamplers.size();
  }

  public double logDensity()
  {
    return 
      sumFixedDensities 
        + annealingExponent * sumPreannealedFiniteDensities
        // ?: to avoid 0 * -INF
        + (nOutOfSupport == 0 ? 0.0 : nOutOfSupport * AnnealedFactor.annealedMinusInfinity(annealingExponent));
  }
  
  @Override
  public double logDensityRatio(double temperature, double nextTemperature) 
  {
    double delta = nextTemperature - temperature;
    return 
      delta * sumPreannealedFiniteDensities
        // ?: to avoid 0 * -INF
        + (nOutOfSupport == 0 ? 
            0.0 : 
            nOutOfSupport * (AnnealedFactor.annealedMinusInfinity(nextTemperature) - AnnealedFactor.annealedMinusInfinity(temperature)));
  }
   
  static Kryo kryo = new Kryo(); {
    DefaultInstantiatorStrategy defaultInstantiatorStrategy = new Kryo.DefaultInstantiatorStrategy();
    defaultInstantiatorStrategy.setFallbackInstantiatorStrategy(new StdInstantiatorStrategy());
    kryo.setInstantiatorStrategy(defaultInstantiatorStrategy);
    kryo.getFieldSerializerConfig().setCopyTransient(false); 
  }
  
//  static Cloner cloner = new Cloner(); {
//    cloner.setNullTransient(true);
//  }
  
  private static Cloner cloner = new Cloner(); // Thread safe
  {
    cloner.setNullTransient(true);
//    cloner.setDumpClonedClasses(true); 
  }
  
  private static ThreadLocal<Kryo> duplicator = new ThreadLocal<Kryo>()
  {
    @Override
    protected Kryo initialValue() 
    {
      Kryo kryo = new Kryo();
      DefaultInstantiatorStrategy defaultInstantiatorStrategy = new Kryo.DefaultInstantiatorStrategy();
      defaultInstantiatorStrategy.setFallbackInstantiatorStrategy(new StdInstantiatorStrategy());
      kryo.setInstantiatorStrategy(defaultInstantiatorStrategy);
      kryo.getFieldSerializerConfig().setCopyTransient(false); 
      return kryo;
    }
  };
  
  public SampledModel duplicate() 
  {
//    SampledModel result = cloner.deepClone(this);
    SampledModel result =  duplicator.get().copy(this);
    return result;
  }
  
  public void posteriorSamplingStep(Random random, int kernelIndex)
  {
    posteriorInvariantSamplers.get(kernelIndex).execute(random);  
    update(kernelIndex);
  }
  
  public void posteriorSamplingStep_deterministicScanAndShuffle(Random random)
  {
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
  
  public void forwardSample(Random random)
  {
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
    annealingExponent = value;
    for (int annealedIndex : allAnnealedFactors)
      factors.get(annealedIndex).setExponent(value); 
  }
  
  public double getExponent()
  {
    return annealingExponent;
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
    public void write(org.eclipse.xtext.xbase.lib.Pair<Object,Object> ... sampleContext)
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
    for (int fixedIndex : allFixedFactors)
    {
      double newCache = factors.get(fixedIndex).logDensity();
      sumFixedDensities += newCache;
      caches[fixedIndex] = newCache;
    }
    
    sumPreannealedFiniteDensities = 0.0;
    nOutOfSupport = 0;
    for (int annealedIndex : allAnnealedFactors)
    {
      double newPreAnnealedCache = factors.get(annealedIndex).enclosed.logDensity();
      caches[annealedIndex] = newPreAnnealedCache;
      
      if (newPreAnnealedCache == Double.NEGATIVE_INFINITY)
        nOutOfSupport++;
      else
        sumPreannealedFiniteDensities += newPreAnnealedCache;
    }
  }
  
  private void update(int samplerIndex)
  {
    if (sumPreannealedFiniteDensities == Double.NEGATIVE_INFINITY || sumFixedDensities == Double.NEGATIVE_INFINITY)
      throw new RuntimeException("Updating particle weights when they have -INF density currently not supported."); // can work around with updateAll(); return; if becomes necessary, but inefficient
    
    for (int fixedIndex : sampler2fixed[samplerIndex])
    {
      double newCache = factors.get(fixedIndex).logDensity();
      sumFixedDensities += newCache - caches[fixedIndex];
      caches[fixedIndex] = newCache;
    }
    
    for (int annealedIndex : sampler2annealed[samplerIndex])
    {
      {
        double oldPreAnneledCache = caches[annealedIndex];
        
        if (oldPreAnneledCache == Double.NEGATIVE_INFINITY)
          nOutOfSupport--;
        else
          sumPreannealedFiniteDensities -= oldPreAnneledCache;
      }
      
      {
        double newPreAnnealedCache = factors.get(annealedIndex).enclosed.logDensity();
        caches[annealedIndex] = newPreAnnealedCache;
        
        if (newPreAnnealedCache == Double.NEGATIVE_INFINITY)
          nOutOfSupport++;
        else
          sumPreannealedFiniteDensities += newPreAnnealedCache;
      }
    }
  }
  
  //// Utility methods setting up caches
  
  private void initSampler2FactorIndices(GraphAnalysis graphAnalysis, BuiltSamplers samplers, Pair<List<AnnealedFactor>, List<Factor>> annealingStructure) 
  {
    Map<AnnealedFactor, Integer> factor2Index = factor2index(factors);
    Set<Factor> annealedFactors = new HashSet<>(annealingStructure.getLeft());
    for (int samplerIndex = 0; samplerIndex < samplers.list.size(); samplerIndex++)
    {
      ObjectNode<?> sampledVariable = samplers.correspondingVariables.get(samplerIndex);
      List<? extends Factor> factors = 
          graphAnalysis.getConnectedFactor(sampledVariable).stream()
            .map(node -> node.object)
            .collect(Collectors.toList());
      List<Integer> 
        annealedIndices = new ArrayList<>(),
        fixedIndices = new ArrayList<>();
      for (Factor f : factors)
        (annealedFactors.contains(factors) ? annealedIndices : fixedIndices).add(factor2Index.get(f));
      sampler2annealed[samplerIndex] = annealedIndices.stream().mapToInt(i->i).toArray();
      sampler2fixed   [samplerIndex] = fixedIndices   .stream().mapToInt(i->i).toArray();
    }
  }

  private static Map<AnnealedFactor, Integer> factor2index(List<AnnealedFactor> factors) 
  {
    Map<AnnealedFactor, Integer> result = new IdentityHashMap<>();
    for (int i = 0; i < factors.size(); i++)
      result.put(factors.get(i), i);
    return result;
  }

  /**
   * Ignore factors that are not LogScaleFactor's (e.g. constraints), make sure everything else are AnnealedFactors.
   */
  private static List<AnnealedFactor> initFactors(Pair<List<AnnealedFactor>, List<Factor>> annealingStructure) 
  {
    ArrayList<AnnealedFactor> result = new ArrayList<>();
    result.addAll(annealingStructure.getLeft());
    for (Factor f : annealingStructure.getRight())
      if (f instanceof LogScaleFactor)
      {
        if (!(f instanceof AnnealedFactor))
          throw new RuntimeException("Currently assuming even fixed factors are of type annealedFactor, their exponent is just not changed.");
        result.add((AnnealedFactor) f);
      }
    return result;
  }
}

package blang.runtime;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.stream.Collectors;

import org.apache.commons.lang3.tuple.Pair;

import com.rits.cloning.Cloner;

import blang.core.AnnealedFactor;
import blang.core.Factor;
import blang.core.ForwardSimulator;
import blang.core.LogScaleFactor;
import blang.core.Model;
import blang.mcmc.BuiltSamplers;
import blang.mcmc.Sampler;
import blang.runtime.objectgraph.GraphAnalysis;
import blang.runtime.objectgraph.ObjectNode;

public class SampledModel
{
  public final Model model;
  private final List<Sampler> posteriorInvariantSamplers;
  private List<ForwardSimulator> forwardSamplers;
  private double annealingExponent;
  
  //// Various caches to make it quick to compute the global density
  
  private final List<AnnealedFactor> factors; 
  
  // sampler index -> factor indices (using array since inner might have lots of small arrays)
  private final int [][] 
      sampler2annealed, // for the factors undergoing annealing
      sampler2fixed;    // and the others ones
  
  private final ArrayList<Integer> allAnnealedFactors = new ArrayList<>();
  private final ArrayList<Integer> allFixedFactors = new ArrayList<>();
  
  private final double [] caches;
  private double sumPreannealedFiniteDensities, sumFixedDensities;
  private int nOutOfSupport;
  
  public SampledModel(GraphAnalysis graphAnalysis, BuiltSamplers samplers) 
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
    
    forwardSample(new Random(1)); 
  }

  public double logDensity()
  {
    return 
      sumFixedDensities 
        + annealingExponent * sumPreannealedFiniteDensities
        // ?: to avoid 0 * -INF
        + (nOutOfSupport == 0 ? 0.0 : nOutOfSupport * AnnealedFactor.annealedMinusInfinity(annealingExponent));
  }
   
  public SampledModel duplicate()
  {
    Cloner cloner = new Cloner();
    return cloner.deepClone(this);
  }
  
  public void posteriorInvariantStep(Random random, int kernelIndex)
  {
    posteriorInvariantSamplers.get(kernelIndex).execute(random);  
    update(kernelIndex);
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

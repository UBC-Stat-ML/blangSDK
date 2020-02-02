package blang.validation;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

import org.junit.Assert;

import bayonet.distributions.ExhaustiveDebugRandom;
import bayonet.math.NumericalUtils;
import blang.core.Model;
import blang.engines.internals.factories.Exact;
import blang.runtime.SampledModel;
import briefj.Indexer;
import briefj.collections.Counter;
import xlinear.DenseMatrix;
import xlinear.MatrixExtensions;
import xlinear.MatrixOperations;
import xlinear.SparseMatrix;

/**
 * Tests for invariance and irreducibility when models are 
 * fully discrete and fits in memory. 
 */
public class DiscreteMCTest 
{
  /**
   * Print diagnostic messages during testing.
   */
  public boolean verbose = false;
  
  /**
   * Bi-directional map between integers and state representatives. 
   * Used to order rows and columns of the matrices and vectors in 
   * the following.
   */
  Indexer<Object> stateIndexer = new Indexer<>();
  
  /**
   * The target distribution is constructed and normalized.  
   * Possible since we can explicitly enumerate all states.
   */
  DenseMatrix targetDistribution;
  
  /**
   * The transition matrix for each MCMC kernel under study.
   */
  List<SparseMatrix> transitionMatrices = new ArrayList<>();
  
  /**
   * Simplified method to create a DiscreteMCTest, wrapping around some of the other tedious 
   * constructors. 
   */
  @SuppressWarnings("unchecked")
  public static <M extends Model> DiscreteMCTest create(M model, Function<M, Object> equality) {
    SampledModel sampled = new SampledModel(model);
    Function<SampledModel, Object> transforedEquality = (sampledModel) -> {
      M m = (M) (sampledModel.model);
      return equality.apply(m);
    };
    return new DiscreteMCTest(sampled, transforedEquality);
  }
  
  /**
   * @param model , should support forward generation (TODO: this could be relaxed by supplying instead an 
   *    exhaustive list of states).
   * @param equalityAssessor Return an object for a given model configuration, .equals and .hashcode will be used on that 
   *    object to index rows and columns of the matrices and vectors corresponding to transition matrices and marginals.
   */
  public DiscreteMCTest(SampledModel model, Function<SampledModel, Object> equalityAssessor) {
    this(model, equalityAssessor, false);
  }
  public DiscreteMCTest(SampledModel model, Function<SampledModel, Object> equalityAssessor, boolean verbose) 
  {
    this.verbose = verbose;
    Counter<Integer> probabilities = new Counter<>();
    Map<Integer,SampledModel> stateCopies = new LinkedHashMap<>();
    
    // Since we are assuming the latent state is fully discrete, we can perform exact inference 
    // by enumerating all possible configurations (via ExhaustiveDebugRandom), computing their unnormalized probabilities, and 
    // normalizing by the sum of all unnormalized probabilities.
    ExhaustiveDebugRandom exhaustive = new ExhaustiveDebugRandom();
    while (exhaustive.hasNext())
    {
      model.forwardSample(exhaustive, true);
      double probability = Math.exp(Exact.logWeight(model, exhaustive));
      Object representative = equalityAssessor.apply(model);
      // At the same time, we create an index of the states (bi-directional map between representatives and integers).
      stateIndexer.addToIndex(representative);
      int index = stateIndexer.o2i(representative);
      probabilities.incrementCount(index, probability);
      stateCopies.put(index, model.duplicate());
    }
    
    
    setup(equalityAssessor, probabilities, model.nPosteriorSamplers(), stateCopies);
  }
  
  /**
   * 
   * @param models set of all possible distinct models w.r.t. equalityAssessor
   * @param equalityAssessor see DiscreteMCTest(SampledModel model, Function<SampledModel, Object> equalityAssessor) 
   */
  public DiscreteMCTest(Collection<SampledModel> models, Function<SampledModel, Object> equalityAssessor) {
    this(models, equalityAssessor, false);
  }
  public DiscreteMCTest(Collection<SampledModel> models, Function<SampledModel, Object> equalityAssessor, boolean verbose) 
  {
    this.verbose = verbose;
    Counter<Integer> probabilities = new Counter<>();
    Map<Integer,SampledModel> stateCopies = new LinkedHashMap<>();
    for (SampledModel model : models) 
    {
      double probability = Math.exp(model.logDensity());
      Object representative = equalityAssessor.apply(model);
      if (stateIndexer.containsObject(representative))
        throw new RuntimeException("Duplicate model not allowed for this constructor: \n" + representative + "\n"
            + "Try the other one if forward sampling supported?");
      stateIndexer.addToIndex(representative);
      int index = stateIndexer.o2i(representative);
      probabilities.incrementCount(index, probability);
      stateCopies.put(index, model);
    }
    
    setup(equalityAssessor, probabilities, models.iterator().next().nPosteriorSamplers(), stateCopies);
  }
  
  private void setup(
      Function<SampledModel, Object> equalityAssessor,
      Counter<Integer> probabilities, 
      int nPosteriorSamplers,
      Map<Integer,SampledModel> stateCopies) 
  {
    probabilities.normalize();
    // Covert the target distribution into a vector
    int nStates = stateIndexer.size();
    targetDistribution = MatrixOperations.dense(1,nStates);
    for (int i = 0; i < nStates; i++)
      targetDistribution.set(i, probabilities.getCount(i));  
    
    println("Target distribution: \n" + targetDistribution);
    
    // Build the transition matrix for each kernel
    for (int kernelIndex = 0; kernelIndex < nPosteriorSamplers; kernelIndex++)
    {
      SparseMatrix matrix = MatrixOperations.sparse(nStates, nStates);
      transitionMatrices.add(matrix);
      for (int i = 0; i < nStates; i++) 
      {
        SampledModel model = stateCopies.get(i);
        // Enumerate all possible transitions allowed by the kernel from the state.
        ExhaustiveDebugRandom exhaustive = new ExhaustiveDebugRandom();
        while (exhaustive.hasNext())
        {
          SampledModel nextModel = model.duplicate();
          nextModel.posteriorSamplingStep(exhaustive, kernelIndex);
          Object nextStateRepresentative = equalityAssessor.apply(nextModel);
          if (!stateIndexer.containsObject(nextStateRepresentative))
            throw new RuntimeException("Bad equalityAssessor or forward generator. \n"
                + "This representative was not found: " + nextStateRepresentative);
          int j = stateIndexer.o2i(nextStateRepresentative);
          // Increment the matrix by the probability of that transition.
          double probability = exhaustive.lastProbability();
          MatrixExtensions.increment(matrix, i, j, probability);
        }
      }
      println("Transition matrix " + kernelIndex + ":\n" + matrix);
    }
  }
  
  /**
   * Check if each individual kernel is pi invariant. 
   * Simply matrix multiply the target and the transition and see if 
   * the same matrix is output (up to numerical precision, 1e-6 by default). 
   */
  public void checkInvariance() 
  {
    int tIndex = 0;
    for (SparseMatrix transitionMatrix : transitionMatrices) 
    {
      DenseMatrix oneStep = targetDistribution.mul(transitionMatrix);
      for (int i = 0; i < targetDistribution.nEntries(); i++)
        Assert.assertEquals(targetDistribution.get(i), oneStep.get(i), NumericalUtils.THRESHOLD);
      println("Invariance of kernel " + (tIndex++) + " established successfully.");
    }
  }
  
  /**
   * Check that the mixture of all kernels is irreducible. 
   */
  public void checkIrreducibility()
  {
    // Mix the kernels and add self transitions.
    int stateSpaceSize = targetDistribution.nEntries();
    double mixProportion = 1.0 / (1.0 + transitionMatrices.size());
    SparseMatrix mixture = MatrixOperations.identity(stateSpaceSize).mul(mixProportion);
    for (SparseMatrix transitionMatrix : transitionMatrices)
      mixture.addInPlace(transitionMatrix.mul(mixProportion));
    
    // Start at an arbitrary state (index 0)
    DenseMatrix currentState = MatrixOperations.dense(1, stateSpaceSize);
    currentState.set(0, 1.0);
    
    // We should be able to reach all states by at most stateSpaceSize steps.
    for (int i = 0; i < stateSpaceSize; i++) 
    {
      currentState = currentState.mul(mixture);
      // Check if we cover the space yet.
      if (currentState.nonZeroEntries().count() == stateSpaceSize) {
        println("Irreducibility achieved in " + (i+1) + " steps.");
        return;
      }
    }
    Assert.fail("Not irreducible: \n" + mixture);
  }
  
  public void checkStateSpaceSize(int expectedSize)
  {
    Assert.assertEquals(expectedSize, targetDistribution.nEntries());
  }
  
  public String reportStateSpace() 
  {
    StringBuilder result = new StringBuilder();
    for (int i = 0; i < stateIndexer.size(); i++)
      result.append("" + i + "\t" + stateIndexer.i2o(i) + "\n");
    return result.toString();
  }
  
  private void println(Object o)
  {
    if (verbose)
      System.out.println(o);
  }
}

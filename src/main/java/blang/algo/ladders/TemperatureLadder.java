package blang.algo.ladders;

import java.util.List;

import blang.algo.AnnealingKernels;
import blang.algo.TemperedParticle;
import blang.inits.Implementations;

/**
 * Provides a temperature ladder for parallel tempering-type algorithms.
 * Difference with a TemperatureSchedule is that the whole chain has to 
 * be provided at once. 
 */
@Implementations({Geometric.class})
public interface TemperatureLadder<P extends TemperedParticle>
{
  /**
   * Fill the provided temperingParameters with annealing parameters (first one should be 1 ~ room temperature)
   * 
   * Optionally, also fill in initialStates with states at the corresponding temperature. 
   */
  void temperingParameters(AnnealingKernels<P> kernels, List<Double> temperingParameters, List<P> initialStates, int nThreads);
}
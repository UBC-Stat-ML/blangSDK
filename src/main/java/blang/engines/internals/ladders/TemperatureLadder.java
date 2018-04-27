package blang.engines.internals.ladders;

import java.util.List;

import blang.inits.Implementations;

/**
 * Provides a temperature ladder for parallel tempering-type algorithms.
 * Difference with a TemperatureSchedule is that the whole chain has to 
 * be provided at once. 
 */
@Implementations({Geometric.class, EquallySpaced.class})
public interface TemperatureLadder
{
  /**
   * Fill the provided temperingParameters with annealing parameters (first one should be 1 ~ room temperature)
   * 
   * Optionally, also fill in initialStates with states at the corresponding temperature. 
   */
  List<Double> temperingParameters(int nTemperatures);
}
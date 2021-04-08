package blang.engines.internals.ladders;

import java.util.List;

import blang.inits.Implementations;

/**
 * Provides a temperature ladder for parallel tempering-type algorithms.
 * Difference with a TemperatureSchedule is that the whole chain has to 
 * be provided at once. 
 */
@Implementations({Geometric.class, EquallySpaced.class, Polynomial.class, UserSpecified.class, FromAnotherExec.class})
public interface TemperatureLadder
{
  /**
   * Fill the provided temperingParameters with annealing parameters (index 0, i.e. first one, should be 1 - i.e. room temperature)
   */
  List<Double> temperingParameters(int nTemperatures);
}
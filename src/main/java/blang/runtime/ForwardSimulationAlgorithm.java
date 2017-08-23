package blang.runtime;

import java.util.List;
import java.util.Random;

import blang.core.Factor;
import blang.core.ForwardSimulator;

public class ForwardSimulationAlgorithm
{
  public static void simulate(Random random, List<? extends Factor> linearizedFactors)
  {
    for (Factor f : linearizedFactors)
    {
      if (!(f instanceof ForwardSimulator))
        throw new RuntimeException("In order to generate data, all factors need to " +
            "implement " + ForwardSimulator.class.getName() + ". This is not the case for " + f.getClass());
      ((ForwardSimulator) f).generate(random);
    }
  }
}

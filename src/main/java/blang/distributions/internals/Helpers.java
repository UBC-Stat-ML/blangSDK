package blang.distributions.internals;

import bayonet.math.NumericalUtils;
import blang.types.StaticUtils;

public class Helpers 
{
  private static boolean warnedUnstableConcentration = false;
  public static double concentrationWarningThreshold = 0.5;
  public static void checkDirichletOrBetaParam(double concentration)
  {
    StaticUtils.check(concentration > 0.0);
    if (!warnedUnstableConcentration && concentration < concentrationWarningThreshold - NumericalUtils.THRESHOLD)
    {
      warnedUnstableConcentration = true;
      System.err.println("Warning: small concentrations may cause numeric instability to Dirichlet and Beta distributions. "
          + "Consider enforcing a lower bound of say " + concentrationWarningThreshold);
    }
  }
  
  private Helpers() {}
}

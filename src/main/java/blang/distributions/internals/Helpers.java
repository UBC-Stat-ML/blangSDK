package blang.distributions.internals;

import bayonet.math.NumericalUtils;

public class Helpers 
{
  public static boolean warnedUnstableConcentration = false;
  public static double concentrationWarningThreshold = 0.5;
  public static void checkDirichletOrBetaParam(double concentration)
  {
    if (!warnedUnstableConcentration && concentration < concentrationWarningThreshold - NumericalUtils.THRESHOLD)
    {
      warnedUnstableConcentration = true;
      System.err.println("Warning: small concentrations may cause numeric instability to Dirichlet and Beta distributions. "
          + "Consider enforcing a lower bound of say " + concentrationWarningThreshold + " "
          + "This message may also occur when slice samling outside of such constraint, you can then ignore this message. ");
    }
  }
  
  private Helpers() {}
}

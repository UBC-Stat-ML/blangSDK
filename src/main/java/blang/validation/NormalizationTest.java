package blang.validation;

import org.apache.commons.math3.analysis.UnivariateFunction;
import org.apache.commons.math3.analysis.integration.SimpsonIntegrator;
import org.apache.commons.math3.analysis.integration.UnivariateIntegrator;
import org.junit.Assert;

import bayonet.math.NumericalUtils;
import blang.core.DistributionAdaptor;
import blang.core.RealDistribution;
import blang.core.RealDistributionAdaptor;
import blang.core.RealVar;
import blang.core.UnivariateModel;

public class NormalizationTest 
{
  protected UnivariateIntegrator integrator = new SimpsonIntegrator();
  protected int maxEval = 100_000_000;
  protected int initialAutoRadius = 8;
  protected int maxNExpansions = 10;
  
  protected void checkNormalization(UnivariateModel<RealVar> distribution)
  {
    checkNormalization(distribution, Double.NaN, Double.NaN);
  }
  
  protected void checkNormalization(UnivariateModel<RealVar> distribution, double left, double right)
  {
    System.out.println("Checking normalization for " + distribution.getClass().getSimpleName());
    
    DistributionAdaptor<RealVar> adaptor = new DistributionAdaptor<>(distribution);
    RealDistribution realDist = new RealDistributionAdaptor(adaptor);
    UnivariateFunction function = x -> Math.exp(realDist.logDensity(x));
    
    boolean expand = Double.isNaN(left);
    if (expand) 
    {
      left = - initialAutoRadius;
      right = initialAutoRadius;
    }
    
    for (int i = 0; i < maxNExpansions; i++)
    {
      
      double integral = integrator.integrate(maxEval, function, left, right);
      System.out.println("\tIntegrating from " + left + " -- " + right + " -> " + integral);
      if (integral > 1.0 + NumericalUtils.THRESHOLD)
        Assert.fail("Normalization greater than one.");
      if (NumericalUtils.isClose(1.0, integral, NumericalUtils.THRESHOLD))
        return;
      
      if (!expand)
        break;
      
      left *= 2.0;
      right *= 2.0;
    }
    Assert.fail("Seems to normalize to less than one.");
    
  }
}

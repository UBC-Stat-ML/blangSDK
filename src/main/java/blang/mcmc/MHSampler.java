package blang.mcmc;

import java.util.List;
import java.util.Random;

import blang.core.LogScaleFactor;
import blang.core.SupportFactor;



public abstract class MHSampler<T> implements Sampler
{
  @SampledVariable
  protected T variable;
  
  @ConnectedFactor
  protected List<SupportFactor> supportFactors;
  
  @ConnectedFactor
  protected List<LogScaleFactor> numericFactors;
  
  private FactorProduct factorProduct = null;
  
  public boolean setup() 
  {
    factorProduct = new FactorProduct(supportFactors, numericFactors);
    return true;
  }
  
  public void execute(Random random)
  {
    // record likelihood before
    final double logBefore = factorProduct.logDensity();
    Callback callback = new Callback()
    {
      private Double proposalLogRatio = null;
      @Override
      public void setProposalLogRatio(double logRatio)
      {
        this.proposalLogRatio = logRatio;
      }
      @Override
      public boolean sampleAcceptance()
      {
        if (proposalLogRatio == null)
          throw new RuntimeException("Use setProposalLogRatio(..) before calling sampleAcceptance()");
        final double logAfter = factorProduct.logDensity();
        final double ratio = Math.exp(proposalLogRatio + logAfter - logBefore);
        return random.nextDouble() < ratio;
      }
    };
    propose(random, callback);
  }
  
  public abstract void propose(Random random, Callback callback);

}
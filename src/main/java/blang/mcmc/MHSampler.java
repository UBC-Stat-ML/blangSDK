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
  
  public void execute(Random random)
  {
    // record likelihood before
    final double logBefore = neighborLogLikelihood();
    MHSampler.Callback callback = new Callback()
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
        final double logAfter = neighborLogLikelihood();
        final double ratio = Math.exp(proposalLogRatio + logAfter - logBefore);
        return random.nextDouble() < ratio;
      }
    };
    propose(random, callback);
  }
  
  public double neighborLogLikelihood()
  {
    for (SupportFactor support : supportFactors)
      if (!support.isInSupport())
        return Double.NEGATIVE_INFINITY;
    
    double sum = 0.0;
    for (LogScaleFactor numericFactor : numericFactors)
      sum += numericFactor.logDensity();
    
    return sum;
  }
  
  public abstract void propose(Random random, Callback callback);
  
  public static interface Callback
  {
    public void setProposalLogRatio(double logRatio);
    public boolean sampleAcceptance();
  }

}
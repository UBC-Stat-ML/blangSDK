package blang.mcmc;

public interface Callback
{
  public void setProposalLogRatio(double logRatio);
  public boolean sampleAcceptance();
}
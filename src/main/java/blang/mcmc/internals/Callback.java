package blang.mcmc.internals;

public interface Callback
{
  public void setProposalLogRatio(double logRatio);
  public boolean sampleAcceptance();
}
package blang.engines.internals;

/**
 * Sequences of distribution of the form: prior x like^temperature
 */
public class AnnealedLikelihoodParticle<P> implements AnnealedParticle
{
  public final double logLikelihood;
  public final P contents;
  
  public AnnealedLikelihoodParticle(double logLikelihood, P contents)
  {
    this.logLikelihood = logLikelihood;
    this.contents = contents;
  }

  @Override
  public double logDensityRatio(double temperature, double nextTemperature)
  {
    return (nextTemperature - temperature) * logLikelihood;
  }
}
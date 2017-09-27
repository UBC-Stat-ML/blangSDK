package blang.engines.internals;

public interface AnnealedParticle
{
  /**
   * pi_nextTemperature / pi_temperature (this)
   */
  double logDensityRatio(double temperature, double nextTemperature);
}
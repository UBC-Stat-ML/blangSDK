package blang.types

import blang.mcmc.Samplers
import blang.mcmc.RealNaiveMHSampler
import blang.core.RealVar

@Samplers(RealNaiveMHSampler)
interface WritableRealVar extends RealVar {
  def void set(double value)
}
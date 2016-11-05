package blang.types

import blang.mcmc.Samplers
import blang.mcmc.IntNaiveMHSampler

import blang.core.IntVar

@Samplers(IntNaiveMHSampler)  
interface WritableIntVar extends IntVar {
  def void set(int value)
}
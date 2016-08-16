package blang.types

import blang.inits.InitVia
import blang.inits.strategies.SelectImplementation

@InitVia(SelectImplementation)
@blang.inits.Implementation(Real.Implementation)

@FunctionalInterface
interface Real {
  def double doubleValue()
  
  static class Implementation
}
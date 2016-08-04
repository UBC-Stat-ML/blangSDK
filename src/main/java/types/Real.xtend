package types

import runtime.DefaultImplementation

@DefaultImplementation(RealImplementation)
@FunctionalInterface
interface Real {
  def double doubleValue()
}
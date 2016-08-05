package blang.types

import blang.runtime.DefaultImplementation

@DefaultImplementation(RealImplementation)
@FunctionalInterface
interface Real {
  def double doubleValue()
}
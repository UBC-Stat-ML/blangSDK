package blang.types

import blang.runtime.DefaultImplementation

@DefaultImplementation(IntImplementation)
@FunctionalInterface
interface Int {
  def int intValue()
}
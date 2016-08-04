package types

import runtime.DefaultImplementation

@DefaultImplementation(IntImplementation)
@FunctionalInterface
interface Int {
  def int intValue()
}
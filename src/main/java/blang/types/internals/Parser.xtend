package blang.types.internals

/**
 * Utility for HashPlate and HashPlated.
 */
@FunctionalInterface
interface Parser<T> {
  def T parse(String string)
}
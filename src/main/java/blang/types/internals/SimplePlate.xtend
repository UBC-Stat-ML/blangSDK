package blang.types.internals

import blang.types.Plate
import blang.types.Index
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Set
import blang.runtime.internals.objectgraph.SkipDependency
import java.util.LinkedHashSet

/**
 * Plate implementation based on an explicit list of indices.
 */
class SimplePlate<T> implements Plate<T> {
  
  @Accessors(PUBLIC_GETTER)
  val ColumnName name
  
  @SkipDependency(isMutable = false)
  val Set<Index<T>> indices
  
  /**
   * Assume a non-jagged array so that parentIndices are ignored.
   */
  override Iterable<Index<T>> indices(Index<?>... parentIndices) {
    return indices
  }
  
  /**
   * This is not needed for SimplePlates. 
   */
  override parse(String string) {
    throw new UnsupportedOperationException
  }
  
  new(ColumnName name, Set<T> keys) {
    this.name = name
    this.indices = new LinkedHashSet 
    for (T key : keys) {
      indices.add(new Index(this, key))
    }
  }
  
}
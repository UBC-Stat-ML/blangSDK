package blang.types.internals

import blang.types.Plate
import blang.types.Index
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Set
import java.util.LinkedHashSet
import com.rits.cloning.Immutable
import java.util.Collection

/**
 * Plate implementation based on an explicit list of indices.
 */
@Immutable
class SimplePlate<T> implements Plate<T> {
  
  @Accessors(PUBLIC_GETTER)
  val ColumnName name
  
  val Set<Index<T>> indices
  
  /**
   * Assume a non-jagged array so that parentIndices are ignored.
   */
  override Collection<Index<T>> indices(Query parentIndices) {
    return indices
  }
  
  /**
   * This is not needed for SimplePlates. 
   */
  override parse(String string) {
    throw new UnsupportedOperationException
  }
  
  new(String name, Set<T> keys) {
    this(new ColumnName(name), keys)
  }
  
  new(ColumnName name, Set<T> keys) {
    this.name = name
    this.indices = new LinkedHashSet 
    for (T key : keys) {
      indices.add(new Index(this, key))
    }
  }
  
  override String toString() {
    return name.string
  }
}
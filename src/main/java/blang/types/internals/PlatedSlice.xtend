package blang.types.internals

import blang.types.Plated
import blang.runtime.internals.objectgraph.SkipDependency
import java.util.Map
import java.util.LinkedHashMap

/**
 * Variables loaded through this class will be inserted into 
 * the parent(s) as well. Not vice versa. 
 * 
 * Dependency analysis for instance of PlatedSlice 
 * will only point to the entries in the 
 * slice, as expected. 
 */
class PlatedSlice<T> implements Plated<T> {
  
  val Map<Query, T> variables = new LinkedHashMap
  
  val Query sliceIndices
  
  @SkipDependency(isMutable = false)  // Otherwise dependency would be too large
  val Plated<T> parent
  
  override T get(Query query) {
    query.indices.addAll(sliceIndices.indices)
    if (variables.containsKey(query)) {
      return variables.get(query)
    }
    val T result = parent.get(query.indices) 
    variables.put(query, result)
    return result
  }
  
  override entries() {
    return variables.entrySet
  }
  
  new(Plated<T> parent, Query sliceIndices) {
    this.parent = parent
    this.sliceIndices = sliceIndices
  }
  
  override String toString() {
    HashPlated::toString(this)
  }
}
package blang.types.internals

import blang.types.Plated
import blang.types.Index
import blang.runtime.internals.objectgraph.SkipDependency
import java.util.Map
import java.util.LinkedHashMap

class PlatedSlice<T> implements Plated<T> {
  
  val Map<Query, T> variables = new LinkedHashMap
  
  @SkipDependency
  val Query sliceIndices
  
  @SkipDependency
  val Plated<T> parent
  
  override T get(Index<?>... indices) {
    val Query query = Query::build(indices)
    query.indices.addAll(sliceIndices.indices)
    if (variables.containsKey(query)) {
      return variables.get(query)
    }
    val T result = parent.get(query.indices) 
    variables.put(query, result)
    return result
  }
  
  override iterator() {
    return variables.entrySet.iterator
  }
  
  new(Plated<T> parent, Query sliceIndices) {
    this.parent = parent
    this.sliceIndices = sliceIndices
  }
  
}
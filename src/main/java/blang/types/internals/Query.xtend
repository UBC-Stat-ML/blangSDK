package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.internals.objectgraph.SkipDependency
import java.util.LinkedHashSet
import blang.types.Index
import blang.types.Plate
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import briefj.CSV

/**
 * Utility for HashPlate and HashPlated.
 */
@Data // important! this is used in hash tables
class Query {
  
  @SkipDependency(isMutable = false)
  val Set<Index<?>> indices
  
  override String toString() {
    if (cachedToString == null) {
      val String [] items = newArrayOfSize(indices.size) 
      var i = 0
      for (item : indices.map[it.key]) {
        items.set(i++, item.toString)
      }
      cachedToString = CSV.toCSV(items)
    }
    return cachedToString
  }
  var transient String cachedToString = null
  def static Query build(Index<?> ... indices) {
    return new Query(new LinkedHashSet(indices))
  }
  def QueryType type() { 
    return new QueryType(indices.map[index | index.plate].toSet)
  }
  @Data
  static class QueryType {
    @Accessors(PUBLIC_GETTER)
    val Set<Plate<?>> plates
  }
}
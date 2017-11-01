package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data
import java.util.LinkedHashSet
import blang.types.Index
import blang.types.Plate
import java.util.Set
import com.rits.cloning.Immutable

/**
 * Utility for HashPlate and HashPlated.
 */
@Data // important! this is used in hash tables
@Immutable
class Query {
  
  val Set<Index<?>> indices
  
  // While queries can use arbitrary order, for storage we expect a deterministic order
  def static Query build(Index<?> ... indices) {
    return new Query(new LinkedHashSet(indices))
  }
  def QueryType type() { 
    return new QueryType(indices.map[index | index.plate].toSet)
  }
  @Data
  @Immutable
  static class QueryType {
    val Set<Plate<?>> plates
  }
}
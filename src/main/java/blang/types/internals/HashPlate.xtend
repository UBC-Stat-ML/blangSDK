package blang.types.internals

import blang.types.Plate
import java.util.Map
import java.util.LinkedHashMap
import java.util.Set
import blang.types.Index
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.LinkedHashSet
import blang.io.DataSource
import java.util.Optional
import com.rits.cloning.Immutable
import java.util.Collection

/**
 * A Plate using a DataSource to load and store indices in a hash table.
 */
@Immutable
class HashPlate<K> implements Plate<K> {
  
  @Accessors(PUBLIC_GETTER)
  val ColumnName name
  
  /**
   * Maximum number of items to load.
   */
  val int maxSize
  
  val Map<Query, Set<Index<K>>> indices = new LinkedHashMap
  
  val IndexedDataSource index
  
  val Parser<K> parser
  
  override Collection<Index<K>> indices(Index<?>... parentIndices) {
    val Query query = Query::build(parentIndices)
    if (indices.containsKey(query)) {
      return indices.get(query)
    }
    val Set<String> keys = index.getStrings(query)
    val Set<Index<K>> result = new LinkedHashSet
    var int i = 0
    for (String key : keys) {
      if (i++ < maxSize) {
        val K parsed = parser.parse(key)
        result.add(new Index(this, parsed))
      }
    }
    indices.put(query, result)
    return result
  }
  
  override K parse(String string) {
    return parser.parse(string)
  }
  
  /**
   * If optionalMaxSize missing, maxSize is set to Integer.MAX_VALUE.
   */
  new(ColumnName name, DataSource dataSource, Parser<K> parser, Optional<Integer> optionalMaxSize) {
    this.name = name
    this.index = new IndexedDataSource(name, dataSource)
    this.parser = parser
    this.maxSize = optionalMaxSize.orElse(Integer.MAX_VALUE)
  }
}
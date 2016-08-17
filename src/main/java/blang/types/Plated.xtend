package blang.types

import java.util.Set
import java.util.Map
import java.util.List
import java.util.HashMap
import java.util.LinkedHashMap
import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.InitContext
import java.util.LinkedHashSet
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashSet

@Data
class Plated {
  
  // raw data
  val Map<String, List<String>> column2RawData = new LinkedHashMap
  
  // cache these sets to avoid looping each time an eachDistinct is called
  val Map<String, Set<String>> columnName2IndexValues = new LinkedHashMap
  
  // keep the init context to parse stuff  
  val InitContext initContext
  
  // cache all queries
  val Map<String, Set<Index<?>>> _eachDistinct_cache = new HashMap
  val Map<GetQuery, Object> _get_cache = new HashMap
  
  // cache the parsed keys
  val Map<Pair<String,String>,Object> _columnAndString2ParsedObject
  
  def private Object getIndexCache(String columnName, String value) {
    return _columnAndString2ParsedObject.get(Pair.of(columnName, value))
  }
  
  def private void putInIndexCache(String columnName, String value, Object parsed) {
    _columnAndString2ParsedObject.put(Pair.of(columnName, value), parsed)
  }
  
  def private int rawSize() {
    if (column2RawData.size === 0) {
      return 0
    }
    return column2RawData.values.iterator.next.size
  }
  
  def <K> Set<Index<K>> eachDistinct(Class<K> type, String columnName) {
    // check if in cache
    if (_eachDistinct_cache.containsKey(columnName)) {
      return _eachDistinct_cache.get(columnName) as Set
    }
    // compute if not
    var Set<Index<K>> result = new LinkedHashSet
    for (String indexValue : columnName2IndexValues.get(columnName)) {
      val K parsed = initContext.parse(type, indexValue)
      putInIndexCache(columnName, indexValue, parsed)
      val Index<K> index = new Index(columnName, parsed)
      result.add(index)
    }
    
    // insert into cache
    _eachDistinct_cache.put(columnName, result as Set)
    
    return result
  }
  
  def <T> T get(Class<T> type, String columnName, Index<?> ... indices) {
    val GetQuery query = new GetQuery(columnName, indices)
    if (_get_cache.containsKey(query)) {
      return _get_cache.get(query) as T
    }
    // compute all cache entries if not
    for (var int dataIdx = 0; dataIdx < rawSize; dataIdx++) {
      val GetQuery curQuery = new GetQuery(columnName)
      for (Index<?> referenceIndex : indices) {
        val String curColumn = referenceIndex.columnName
        val String curIndexValue = column2RawData.get(curColumn).get(dataIdx)
        val Object parsed = getIndexCache(curColumn, curIndexValue)
        val Index<?> curIndex = new Index(columnName, parsed)
        curQuery.indices.add(curIndex)
      }
      if (_get_cache.containsKey(curQuery)) {
        throw new RuntimeException("More than one result for a given get(..) query")
      }
      val T parsedValue = initContext.parse(type, column2RawData.get(columnName).get(dataIdx))
      _get_cache.put(curQuery, parsedValue)
    }
    
    return _get_cache.get(query) as T
  }
  
  
  @Data
  static class Index<K> {
    @Accessors(PUBLIC_GETTER)
    val String columnName
    
    @Accessors(PUBLIC_GETTER)
    val K value
  }
  
  @Data
  private static class GetQuery {
    val Set<Index<?>> indices
    val String columnName
    new (String columnName, Index<?> ... indices) {
      this.indices = new HashSet(indices)
      this.columnName = columnName
    }
    new (String columnName) {
      this.indices = new HashSet
      this.columnName = columnName
    }
  }
  
}
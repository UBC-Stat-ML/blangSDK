package blang.types

import org.eclipse.xtend.lib.annotations.Data
import java.util.Set
import java.util.Map
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.stream.Stream
import java.util.Collection
import java.util.List
import java.util.HashSet
import java.util.HashMap

// TODO: make an interface
class Table<V> {
  
  // Note: these two might not be needed beyond init!
//  val String varName
//  val Class<?> varType

//  val RawData<V> data
  
  // columnName -> possible index values
  val Map<String, Set<Index<?>>> indicesCache = new LinkedHashMap
  
//  @Data
//  static class RawEntry<V> {
//    val V variableValue
//    val Map<
//  }

  @Data
  private static class RawData<V> {
    
    def V getValue(int rowIndex) {
      throw new RuntimeException  
    }
    
    def String getIndexString(int rowIndex, String columnName) {
      throw new RuntimeException
    }
    
    def Set<String> getIndexStrings(String columnName) {
      throw new RuntimeException
    }
    
  }
  
  // some kind of data iterator interface..
  
//  val Map<Indices, V> data = new LinkedHashMap
  
//  new(String s) { // InitializationContext
//    // TODO: read dims or csv in
//  }
  
  // cache: Query
  
  val Map<Indices, V> _get_cache = new HashMap
  
  def V get(Index<?> ... indices) {
    val Indices key = new Indices(indices)
    var V result = _get_cache.get(key)
    if (result !== null) {
      return result
    }
    // trigger full cache computation for this query pattern
    
    
    return get(indices)
  }
  
  def Table<V> subTable(Index<?> ... indices) {
    
  }
  
//  def <K> Set<Index<K>> eachDistinct(Class<K> type, String columnName) {
//    val Set<Index<?>> cached = indicesCache.get(columnName)
//    if (cached !== null) {
//      return cached as Set<Index<K>>
//    }
//    val Set<Index<K>> result = new LinkedHashSet
//    indicesCache.put(columnName, result as Set<Index<?>>)
//    
//    for (String indexString : data.getIndexStrings(columnName)) {
//      val K indexContents = instantiateFromString(type, indexString, columnName)
//      result.add(new Table.Index(columnName, indexContents))
//    }
//    
//    return result
//  }
  
  def static <K> K instantiateFromString(Class<K> type, String initString, String varName) {
    // TODO: move somewhere global? 
    
    // need to follow annotation first   
    // warning: is this going to be slow - not here, and even for the value, that can be made faster
    // note: DO NOT cache though!
    // TODO: try AutoInit
    
    // then, constructor
  }
  
  
  @Data
  private static class Indices {
    val Set<Index<?>> indices
    new (Index<?> ... indices) {
      indices = new HashSet(indices)
    }
  }
 

  // 2 passes on data
  // 1. for each column, set of strings
  // 2. 

  // column -> [ column-cache, i.e. (string -> index) ]
  // 


//  @Data
//  static class Column<K> {
//    val String indexName
//    val Class<K> type
//  }

//  @Data
//  static class Query<K> {
//    Set<String> columns
//  }

  @Data
  static class Index<K> {
//    val Column<K> column
    val String columnName
    val K indexContents
  }
}
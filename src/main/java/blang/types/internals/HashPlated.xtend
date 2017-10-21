package blang.types.internals

import blang.types.Plated
import blang.types.Index
import blang.runtime.internals.objectgraph.SkipDependency
import blang.io.DataSource
import java.util.Map
import blang.io.NA
import java.util.LinkedHashMap
import blang.types.internals.Query.QueryType

/**
 * A Plated using a DataSource to load and store random variables or parameters in a hash table.
 */
class HashPlated<T> implements Plated<T> {
  
  val ColumnName columnName
  
  val Map<Query, T> variables = new LinkedHashMap
  
  @SkipDependency(isMutable = false)
  transient val IndexedDataSource index
  
  @SkipDependency(isMutable = false)
  transient val Parser<T> parser
  
  override T get(Index<?>... indices) {
    val Query query = Query::build(indices)
    if (variables.containsKey(query)) {
      return variables.get(query)
    }
    val T result = parser.parse(getString(query))
    variables.put(query, result)
    return result
  }
  
  private def String getString(Query query) {
    if (!index.dataSource.present) {
      return NA::SYMBOL
    } 
    return index.getString(query)
  }
  
  new(ColumnName columnName, DataSource dataSource, Parser<T> parser) {
    this.columnName = columnName
    this.index = new IndexedDataSource(columnName, dataSource, false)
    this.parser = parser
  }
  
  override iterator() {
    return variables.entrySet.iterator
  }
  
  override String toString() {
    return toString(this)
  }
  
  def static <T> String toString(Plated<T> plated) {
    val StringBuilder result = new StringBuilder
    var boolean first = true
    for (entry : plated) {
      if (first) {
        result.append(entry.key.indices.map[plate.name].join("\t") + "\tvalue" + "\n")
        first = false
      }
      result.append(entry.key.indices.map[key].join("\t") + "\t" + entry.value + "\n")
    }
    return result.toString
  }
}
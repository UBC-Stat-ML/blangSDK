package blang.types.internals

import blang.types.Plated
import blang.types.Index
import blang.runtime.objectgraph.SkipDependency
import blang.io.DataSource
import java.util.Map
import blang.types.NA
import java.util.LinkedHashMap
import blang.types.internals.Query.QueryType

/**
 * A Plated using a DataSource to load and store random variables or parameters in a hash table.
 */
class HashPlated<T> implements Plated<T> {
  
  val ColumnName columnName
  
  val Map<Query, T> variables = new LinkedHashMap
  
  @SkipDependency
  transient val IndexedDataSource index
  
  @SkipDependency
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
}
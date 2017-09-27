package blang.io

import blang.inits.Input
import java.util.Optional
import blang.inits.DesignatedConstructor
import blang.inits.Arg
import blang.inits.DefaultValue
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Set
import java.util.Collections
import blang.types.internals.ColumnName
import blang.io.internals.CSV
import blang.io.internals.GlobalDataSourceStore
import blang.io.internals.DataSourceReader

/**
 * Description of an optional data source.
 */
class DataSource {
  
  /*
   * The optional path could be file system path, database connection path, etc
   * Not specifying the path is useful in situations such as generation from prior.
   */
  public val Optional<String> path
  
  @Arg @DefaultValue("CSV")
  @Accessors(PUBLIC_SETTER)
  DataSourceReader reader = new CSV
 
  @DesignatedConstructor 
  new(@Input(formatDescription = "Path to the DataSource.") Optional<String> path) {
    this.path = path
  }
  
  def Iterable<Map<ColumnName,String>> read() {
    return reader.read(path.get)
  }
  
  def Set<ColumnName> columnNames() {
    val Map<ColumnName,String> head = read().head
    if (head == null) {
      return Collections::emptySet
    } else {
      return head.keySet
    }
  }
  
  def boolean isPresent() {
    return path.present
  }
  
  def static DataSource empty() {
    return new DataSource(Optional.empty)
  }
  
  def static DataSource scopedDataSource(DataSource local, GlobalDataSourceStore global) {
    if (local.present) {
      return local
    } else if (global.dataSource.present) {
      return global.dataSource
    } else {
      return empty
    }
  }
  
}
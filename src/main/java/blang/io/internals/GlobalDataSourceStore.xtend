package blang.io.internals

import blang.io.DataSource
import blang.io.GlobalDataSource

/**
 * Maintains the GlobalDataSource if any. 
 */
class GlobalDataSourceStore {
  public DataSource dataSource = DataSource.empty
  def void set(GlobalDataSource dataSource) {
    if (this.dataSource.present) {
      throw new RuntimeException("There can be only one global data source.")
    }
    this.dataSource = dataSource
  }
}
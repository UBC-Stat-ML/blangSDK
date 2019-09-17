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
      if (dataSource.path.present)
        throw new RuntimeException("There can be only one global data source.")
      else
        // no harm: just ignore
        return 
    }
    this.dataSource = dataSource
  }
}
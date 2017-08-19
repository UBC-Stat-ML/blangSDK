package blang.io

/**
 * Maintains the GlobalDataSource if any. 
 */
class GlobalDataSourceStore {
  public DataSource dataSource = DataSource.empty
  def void set(GlobalDataSource dataSource) {
    if (dataSource.present) {
      throw new RuntimeException("There can be only one global data source.")
    }
    this.dataSource = dataSource
  }
}
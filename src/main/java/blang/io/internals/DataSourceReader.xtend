package blang.io.internals

import java.util.Map
import blang.inits.Implementations
import blang.types.internals.ColumnName 
import blang.io.internals.CSV

@Implementations(CSV)
interface DataSourceReader {
  /**
   * Iterate over all the entries in the provided path. 
   */
  def Iterable<Map<ColumnName,String>> read(String path) 
}

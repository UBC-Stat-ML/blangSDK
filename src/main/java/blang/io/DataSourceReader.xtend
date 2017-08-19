package blang.io

import java.util.Map
import blang.inits.Implementations
import blang.io.formats.CSV
import blang.types.internals.ColumnName 

@Implementations(CSV)
interface DataSourceReader {
  /**
   * Iterate over all the entries in the provided path. 
   */
  def Iterable<Map<ColumnName,String>> read(String path) 
}

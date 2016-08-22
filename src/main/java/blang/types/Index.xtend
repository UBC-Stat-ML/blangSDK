package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Accessors
import blang.runtime.objectgraph.SkipDependency

@Data // important! this is used in hash tables
class Index<K> {  // use cases for K: Integer, String, date or space coordinates
  @Accessors(PUBLIC_GETTER)
  @SkipDependency
  val Plate<K> plate
  
  @Accessors(PUBLIC_GETTER)
  @SkipDependency
  val K value
}
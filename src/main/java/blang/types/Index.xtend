package blang.types

import org.eclipse.xtend.lib.annotations.Data
import blang.runtime.objectgraph.SkipDependency

/**
 * An Index of type K in a specified Plate.
 * 
 * K: the type of key, such as Integer, String, date or space coordinate
 * It is assumed that K is not a random variable.
 */
@Data // important! this is used in hash tables
class Index<K> {  

  @SkipDependency
  public val Plate<K> plate 
  
  @SkipDependency
  public val K key 
}
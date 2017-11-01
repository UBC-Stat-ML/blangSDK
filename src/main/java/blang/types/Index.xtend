package blang.types

import org.eclipse.xtend.lib.annotations.Data

/**
 * An Index of type K in a specified Plate.
 * 
 * K: the type of key, such as Integer, String, date or space coordinate
 * It is assumed that K is Immutable (and not a random variable).
 */
@Data // important! this is used in hash tables
class Index<K> {  
  public val Plate<K> plate 
  public val K key 
}
package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data 

/**
 * Column names for data set read from files or databases.
 * Case insensitive and spaces are dropped.
 */
@Data
class ColumnName {
  public val String string
  new(String string) {
    this.string = string.replaceAll("\\s+", "").toLowerCase
  }
}
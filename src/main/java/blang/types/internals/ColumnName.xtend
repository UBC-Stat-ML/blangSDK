package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data import blang.inits.DesignatedConstructor
import blang.inits.Input

/**
 * Column names for data set read from files or databases.
 * Case insensitive and spaces are dropped.
 */
@Data
class ColumnName {
  public val String string
  @DesignatedConstructor
  new(@Input String string) {
    this.string = string.replaceAll("\\s+", "").toLowerCase
  }
}
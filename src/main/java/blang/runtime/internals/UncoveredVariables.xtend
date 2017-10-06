package blang.runtime.internals

import org.eclipse.xtend.lib.annotations.Data
import java.util.Set

@Data
class UncoveredVariables extends RuntimeException {
  val Set<Class<?>> offendingClasses
  override String toString() {
    return '''Variables of the following types were not covered by samplers: «offendingClasses.map[it.simpleName].join(",")»'''
  }
}
package blang.utils

import java.util.List
import java.util.ArrayList

class StaticUtils {
  
  def static List<Integer> range(int max) {
    val List<Integer> result = new ArrayList
    for (var int i = 0; i < max; i++) {
      result.add(i)
    }
    return result
  }
  
  def static double logistic(double value) {
    return 1.0 / (1.0 + Math.exp(-value))
  }
  
  def static <T> T pickUnique(Iterable<T> collection, String errorMessage) {
    // TODO: add some mechanism to report more informative error messages
    if (collection.size() != 1) {
      throw new RuntimeException('''
        «errorMessage»
        Details: Expected collection of size 1 but found a collection of size «collection.size»''')
    }
    return collection.iterator().next()
  }
}
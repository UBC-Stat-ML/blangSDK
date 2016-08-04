package utils

import java.util.List
import java.util.ArrayList
import java.util.Collection

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
  
  def static <T> T pickUnique(Iterable<T> collection) {
    if (collection.size() != 1) {
      throw new RuntimeException('''Expected collection of size 1 but found a collection of size «collection.size»''')
    }
    return collection.iterator().next()
  }
}
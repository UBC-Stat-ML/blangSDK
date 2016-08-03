package utils

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
}
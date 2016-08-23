package blang.types

import xlinear.Matrix
import org.eclipse.xtend.lib.annotations.Data

class Simplex {
  
  def double get(int index) {
    throw new RuntimeException
    // TODO
  }
  
  def int dim() {
    throw new RuntimeException
  }
  
//  /** Leaving out the last one */
//  val Matrix probabilities
//  
//  new (Matrix probabilities) {
//    // TODO: check it sums to less than one, positive
//    // also, that it's a vector
//    this.probabilities = probabilities
//  }
//  
//  def double get(int index) {
//    
//  }
//  
//  def int size() {
//    return probabilities.nEntries() + 1
//  }
  
}
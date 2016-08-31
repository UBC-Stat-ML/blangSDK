package blang.processing

import java.io.PrintWriter
import java.util.Deque
import java.util.LinkedList
import java.util.List
import java.util.Map
import xlinear.Matrix

class SimpleCSVWriter {
  
  val Deque<String> prefixes = new LinkedList()
  val PrintWriter writer
  
  def void close() { writer.close() }
  
  new (PrintWriter writer) {
    prefixes.add("")
    this.writer = writer
  }
  
  def void setPrefix(List newPrefixes) {
    if (this.prefixes.size() != 1) {
      throw new RuntimeException
    }
    this.prefixes.pollLast()
    this.prefixes.add(newPrefixes.map[toString()].join(",") + ",")
  }
   
  def void recurse(Object addToPrefix, Object item) {
    val String oldPrefix = prefixes.peekLast
    val String newPrefix = oldPrefix + addToPrefix + ","
    prefixes.addLast(newPrefix)
    write(item)
    if (prefixes.pollLast != newPrefix) {
      throw new RuntimeException
    }
  }
  
  
  def protected _writeCSVLine(String s) {
    writer.write(s + "\n")
  }
  
  def dispatch void write(Object object) {
    _writeCSVLine(prefixes.peekLast + object)
  }
  
  def dispatch void write(Map<?,?> map) {
    for (Object key : map.keySet()) {
      recurse(key, map.get(key))
    }
  }
  
  def dispatch void write(Iterable<?> iterable) {
    var int i = 0
    for (Object item : iterable) {
      recurse(i++, item)
    }
  }
  
  def dispatch void write(Matrix m) {
    if (m.isVector()) {
      for (var int i = 0; i < m.nEntries; i++) {
        recurse(i, m.get(i))
      }
    } else {
      for (var int r = 0; r < m.nRows; r++) {
        for (var int c = 0; c < m.nCols; c++) {
          recurse("" + r + "," + c, m.get(r, c))
        }
      }
    }
  }
  
//  def static void main(String [] args) {
//    val SimpleCSVWriter s = new SimpleCSVWriter
//    val Map<String,List<String>> tset = new HashMap
//    tset.put("first key", #["val1", "val2"])
//    tset.put("secong key", #["asdf"])
//    s.write(tset)
//    val Matrix m = MatrixOperations::dense(5,5)
//    s.write(m)
//  }
}
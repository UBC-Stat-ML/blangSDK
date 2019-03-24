package blang.io

import blang.inits.experiments.tabwriters.TidySerializer
import blang.inits.DesignatedConstructor
import blang.inits.GlobalArg
import blang.inits.experiments.ExperimentResults
import xlinear.Matrix
import blang.inits.experiments.tabwriters.TabularWriter
import xlinear.StaticUtils
import blang.types.Plated
import java.util.Map.Entry
import blang.types.internals.Query
import blang.types.Index
import blang.types.PlatedMatrix

class BlangTidySerializer extends TidySerializer { 
  
  @DesignatedConstructor
  new(@GlobalArg ExperimentResults result) {
    super(result)
  } 
  
  def dispatch protected void serializeImplementation(Matrix m, TabularWriter writer) {
    if (m.isVector) {
      for (var int i = 0; i < m.nEntries; i++) {
        writer.write("entry" -> i, TidySerializer::VALUE -> m.get(i))
      }
    } else {
      StaticUtils::visitSkippingSomeZeros(m) [ int row, int col, double value |
        writer.write("row" -> row, "col" -> col, TidySerializer::VALUE -> value)
      ]
    }
  }
  
  def dispatch protected void serializeImplementation(Plated p, TabularWriter writer) {
    for (_entry : p.entries) { 
      val Entry<Query,?> entry = _entry as Entry // work around type inference bug
      var TabularWriter childWriter = writer
      for (Index<?> index : entry.key.indices) {
        childWriter = childWriter.child(index.plate.name.string, index.key)
      }
      serializeImplementation(entry.value, childWriter)
    }
  }
  
  def dispatch protected void serializeImplementation(PlatedMatrix p, TabularWriter writer) {
    for (_entry : p.entries) { 
      val Entry<Query,?> entry = _entry as Entry // work around type inference bug
      var TabularWriter childWriter = writer
      for (Index<?> index : entry.key.indices) {
        childWriter = childWriter.child(index.plate.name.string, index.key)
      }
      val currentMatrix = entry.value as Matrix
      val rowIndexer = p.rowIndexer(entry.key)
      val colIndexer = p.colIndexer(entry.key)
      for (r : 0 ..< currentMatrix.nRows) {
        val rowWriter = childWriter.child(p.rowPlate.name.string, rowIndexer.i2o(r).key)
        for (c : 0 ..< currentMatrix.nCols) {
          val actualWriter =  // cases for vector vs matrix
            if (colIndexer === null) 
              rowWriter 
            else 
              rowWriter.child(p.colPlate.name.string, colIndexer.i2o(c).key)
          serializeImplementation(currentMatrix.get(r, c), actualWriter)
        }
      }
    }
  }
}
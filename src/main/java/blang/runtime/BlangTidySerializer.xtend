package blang.runtime

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

class BlangTidySerializer extends TidySerializer {
  
  @DesignatedConstructor
  new(@GlobalArg ExperimentResults result) {
    super(result)
  } 
  
  def dispatch protected void serializeImplementation(Matrix m, TabularWriter writer) {
    if (m.isVector) {
      for (var int i = 0; i < m.nEntries; i++) {
        writer.write("entry" -> i, "value" -> m.get(i))
      }
    } else {
      StaticUtils::visitSkippingSomeZeros(m) [ int row, int col, double value |
        writer.write("row" -> row, "col" -> col, "value" -> value)
      ]
    }
  }
  
  def dispatch protected void serializeImplementation(Plated<?> p, TabularWriter writer) {
    for (Entry<Query, ?> entry : p) {
      var TabularWriter childWriter = writer
      for (Index<?> index : entry.key.indices) {
        childWriter = writer.child(index.plate.name.string, index.key)
      }
      serializeImplementation(entry.value, childWriter)
    }
  }
}
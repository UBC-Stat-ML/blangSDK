package blang.io

import blang.inits.ProvidesFactory
import java.util.List
import blang.inits.ConstructorArg
import java.io.File
import blang.inits.InitService
import com.google.inject.TypeLiteral
import blang.inits.Creator
import java.util.ArrayList
import briefj.BriefIO
import blang.core.IntVar
import blang.inits.Input
import blang.inits.GlobalArg
import java.util.Optional
import blang.types.internals.IntScalar
import blang.core.RealVar
import blang.types.internals.RealScalar
import blang.inits.providers.CoreProviders 
import xlinear.Matrix
import xlinear.MatrixOperations
import xlinear.DenseMatrix
import xlinear.SparseMatrix
import blang.runtime.Observations
import blang.inits.DefaultValue
import blang.runtime.internals.objectgraph.MatrixConstituentNode
import static extension blang.io.NA.isNA
import blang.types.DenseSimplex
import blang.types.DenseTransitionMatrix
import blang.core.RealConstant
import blang.core.IntConstant
import blang.inits.providers.CollectionsProviders

class Parsers {
  
  @ProvidesFactory
  def static RealVar parseRealVar(     // NOTE: we use Input here so that parsing Lists, etc works
    @Input(formatDescription = "A number or NA") String str,
    @GlobalArg Observations initContext
  ) {
    return
      if (str.isNA) {
        new RealScalar(0.0)
      } else {
        initContext.markAsObserved(new RealConstant(CoreProviders.parseDouble(str)))
      }
  }
  
  @ProvidesFactory
  def static IntVar parseIntVar(
    @Input(formatDescription = "An integer or NA") String str,
    @GlobalArg Observations initContext
  ) {
    return
      if (str.isNA) {
        new IntScalar(0)
      } else {
        initContext.markAsObserved(new IntConstant(CoreProviders.parse_int(str)))
      }
  }
  
  @ProvidesFactory
  def static Matrix parseMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value.") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> providedNRows,
    @ConstructorArg(value = "nCols") Optional<Integer> providedNCols,
    @ConstructorArg(value = "sparse") @DefaultValue("false") boolean sparse
  ) {
    if (sparse && (!providedNRows.present || !providedNCols.present)) {
      throw new RuntimeException("If a sparse matrix is used, then the number of rows and columns must be specified")
    }
    var nRows = providedNRows.orElse(0)
    var nCols = providedNCols.orElse(0)
    if (!providedNRows.present || !providedNCols.present) {
      for (List<String> line : BriefIO.readLines(file).splitCSV()) {
        if (!line.isEmpty()) {
          val int row = CoreProviders.parse_int(line.get(0))
          val int col = CoreProviders.parse_int(line.get(1))
          if (!providedNRows.present) { nRows = Math.max(nRows, row + 1) }
          if (!providedNCols.present) { nCols = Math.max(nCols, col + 1) }
        }
      }
    }
    val Matrix result = 
      if (sparse) {
        MatrixOperations::sparse(nRows, nCols)
      } else {
        MatrixOperations::dense(nRows, nCols)
      }
    var boolean foundNA = false
    for (List<String> line : BriefIO.readLines(file).splitCSV()) {
      if (!line.isEmpty()) {
        if (line.size() != 3) {
          throw new RuntimeException
        }
        val int row = CoreProviders.parse_int(line.get(0))
        val int col = CoreProviders.parse_int(line.get(1))
        val String str = line.get(2)
        if (str.isNA) {
          foundNA = true
          // nothing to do, leave set to 0
        } else {
          initContext.markAsObserved(new MatrixConstituentNode(result, row, col))
          result.set(row, col, CoreProviders.parse_double(str))
        }
      }
    }
    return if (foundNA) {
      result
    } else {
      result.readOnlyView
    }
  }
  
  @ProvidesFactory
  def static DenseMatrix parseDenseMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value.") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> nRows,
    @ConstructorArg(value = "nCols") Optional<Integer> nCols
  ) {
    return parseMatrix(file, initContext, nRows, nCols, false) as DenseMatrix
  }
  
  @ProvidesFactory
  def static SparseMatrix parseSparseMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value.") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> nRows,
    @ConstructorArg(value = "nCols") Optional<Integer> nCols
  ) {
    return parseMatrix(file, initContext, nRows, nCols, true) as SparseMatrix
  }
  
  @ProvidesFactory
  def static DenseSimplex parseSimplex(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the value. Include the redundant entry, i.e. the sum of the read values should be one.") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> nRows,
    @ConstructorArg(value = "nCols") Optional<Integer> nCols
  ) {
    val int nObservedBefore = initContext.observationRoots.size
    val DenseMatrix m = parseDenseMatrix(file, initContext, nRows, nCols)
    if (initContext.observationRoots.size - nObservedBefore != m.nEntries) {
      throw new RuntimeException("Only supporting fully observed or fully unobserved simplex at the moment.")
    }
    return new DenseSimplex(m.readOnlyView)
  }
  
  @ProvidesFactory
  def static DenseTransitionMatrix parseTransitionMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value. Include the redundant ones, i.e. the sum of the read rows should be one..") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> nRows,
    @ConstructorArg(value = "nCols") Optional<Integer> nCols
  ) {
    val int nObservedBefore = initContext.observationRoots.size
    val DenseMatrix m = parseDenseMatrix(file, initContext, nRows, nCols)
    if (initContext.observationRoots.size - nObservedBefore != m.nCols * m.nRows) {
      throw new RuntimeException("Only supporting fully observed or fully unobserved transition matrices at the moment.")
    }
    return new DenseTransitionMatrix(m.readOnlyView)
  }
  
  @ProvidesFactory
  def static <T> List<T> parseList(
    @Input(formatDescription = 
      "Space separated items or \"" + LOAD_KEYWORD + 
      " <path>\" to load from newline separated file") 
    List<String> _strings,
    @InitService TypeLiteral<List<T>> actualType,
    @InitService Creator              creator
  ) {
    val Optional<File> sourceFile = fileSource(_strings)
    val List<String> strings = if (sourceFile.present) {
      val List<String> loaded = new ArrayList
      for (String line : BriefIO.readLines(sourceFile.get)) {
        loaded.add(line)
      }
      loaded
    } else 
      _strings
    return CollectionsProviders::parseList(strings, actualType, creator)
  }
  
  val static String LOAD_KEYWORD = "file"
  def static Optional<File> fileSource(List<String> strings) {
    if (strings.empty) return Optional.empty
    if (strings.get(0) != LOAD_KEYWORD) return Optional.empty
    if (strings.size != 2) throw new RuntimeException("Load file keyword takes exactly one argument (the path to the file)")
    val File result = new File(strings.get(1))
    if (!result.exists) {
      throw new RuntimeException("File not found: " + result)
    }
    return Optional.of(result)
  }
  
}
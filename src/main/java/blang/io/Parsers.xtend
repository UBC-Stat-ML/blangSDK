package blang.io

import blang.inits.ProvidesFactory
import java.util.List
import blang.inits.ConstructorArg
import java.io.File
import blang.inits.InitService
import com.google.inject.TypeLiteral
import blang.inits.Creator
import java.lang.reflect.ParameterizedType
import java.util.ArrayList
import briefj.BriefIO
import blang.inits.parsing.SimpleParser
import blang.core.IntVar
import blang.inits.Input
import blang.inits.GlobalArg
import java.util.Optional
import blang.types.IntScalar
import blang.core.RealVar
import blang.types.RealScalar
import blang.inits.providers.CoreProviders
import xlinear.Matrix
import xlinear.MatrixOperations
import xlinear.DenseMatrix
import xlinear.SparseMatrix
import blang.runtime.Observations
import blang.inits.DefaultValue
import blang.runtime.internals.objectgraph.MatrixConstituentNode
import blang.types.StaticUtils
import static extension blang.io.NA.isNA
import blang.types.DenseSimplex
import blang.types.DenseTransitionMatrix

class Parsers {
  
  @ProvidesFactory
  def static RealVar parseRealVar(     // NOTE: we use Input here so that parsing Lists, etc works
    @Input(formatDescription = "A number or NA") String str,
    @GlobalArg Observations initContext
  ) {
    return
      if (str.isNA) {
        new RealScalar(0.1)
      } else {
        initContext.markAsObserved(new RealScalar(Double.parseDouble(str)))
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
        initContext.markAsObserved(new IntScalar(CoreProviders.parse_int(str)))
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
        val int row = Integer.parseInt(line.get(0))
        val int col = Integer.parseInt(line.get(1))
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
    for (List<String> line : BriefIO.readLines(file).splitCSV()) {
      if (!line.isEmpty()) {
        if (line.size() != 3) {
          throw new RuntimeException
        }
        val int row = Integer.parseInt(line.get(0))
        val int col = Integer.parseInt(line.get(1))
        val String str = line.get(2)
        if (str.isNA) {
          // nothing, leave set to 0
        } else {
          initContext.markAsObserved(new MatrixConstituentNode(result, row, col))
          result.set(row, col, Double.parseDouble(str))
        }
      }
    }
    return result
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
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the value. Include the redundant one.") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> nRows,
    @ConstructorArg(value = "nCols") Optional<Integer> nCols
  ) {
    val DenseMatrix m = parseDenseMatrix(file, initContext, nRows, nCols)
    return StaticUtils::denseSimplex(m)
  }
  
  @ProvidesFactory
  def static DenseTransitionMatrix parseTransitionMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value. Include the redundant ones.") File file,
    @GlobalArg Observations initContext,
    @ConstructorArg(value = "nRows") Optional<Integer> nRows,
    @ConstructorArg(value = "nCols") Optional<Integer> nCols
  ) {
    val DenseMatrix m = parseDenseMatrix(file, initContext, nRows, nCols)
    return StaticUtils::denseTransitionMatrix(m)
  }
  
  @ProvidesFactory
  def static <T> List<T> parseList(
    @ConstructorArg(value = "file", description = "Each line will be an item in the list") File file,
    @InitService TypeLiteral<List<T>> actualType,
    @InitService Creator              creator
  ) {
    if (!file.exists) {
      throw new RuntimeException("File not found: " + file)
    }
    val TypeLiteral<T> typeArgument = 
      TypeLiteral.get((actualType.type as ParameterizedType).actualTypeArguments.get(0))
      as TypeLiteral<T>
    val List<T> result = new ArrayList
    for (String string : BriefIO.readLines(file)) {
      result.add(creator.init(typeArgument, SimpleParser.parse(string)))
    }
    return result
  }
  
}
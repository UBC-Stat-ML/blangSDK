package blang.utils

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
import blang.types.IntVar
import blang.inits.Input
import blang.inits.GlobalArg
import blang.runtime.ObservationProcessor
import java.util.Optional
import blang.types.IntVar.IntScalar
import blang.types.NA
import blang.types.RealVar
import blang.types.RealVar.RealScalar
import blang.inits.providers.CoreProviders
import xlinear.Matrix
import blang.types.Simplex
import xlinear.MatrixOperations
import xlinear.DenseMatrix
import xlinear.SparseMatrix

class Parsers {
  
  @ProvidesFactory
  def static RealVar parseRealVar(    
    @Input(formatDescription = "A number or NA") String str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (str == NA::SYMBOL) {
        new RealScalar(0.0)
      } else {
        initContext.markAsObserved(new RealScalar(Double.parseDouble(str)))
      }
  }
  
  @ProvidesFactory
  def static IntVar parseIntVar(
    @Input(formatDescription = "An integer or NA") String str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (str == NA::SYMBOL) {
        new IntScalar(0)
      } else {
        initContext.markAsObserved(new IntScalar(CoreProviders.parse_int(str)))
      }
  }
  
  @ProvidesFactory
  def static Matrix parseMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value.") File file,
    @GlobalArg ObservationProcessor initContext,
    @ConstructorArg(value = "nRows") int nRows,
    @ConstructorArg(value = "nCols") int nCols,
    @ConstructorArg(value = "sparse", description = "Use a sparse matrix, else, a dense one (default is false)") Optional<Boolean> sparseOptional
  ) {
    val boolean sparse = sparseOptional.orElse(false)
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
        if (str == NA::SYMBOL) {
          // nothing, leave set to 0
        } else {
          initContext.markAsObserved(ExtensionUtils::getRealVar(result, row, col))
          result.set(row, col, Double.parseDouble(str))
        }
      }
    }
    return result
  }
  
  @ProvidesFactory
  def static DenseMatrix parseDenseMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value.") File file,
    @GlobalArg ObservationProcessor initContext,
    @ConstructorArg(value = "nRows") int nRows,
    @ConstructorArg(value = "nCols") int nCols
  ) {
    return parseMatrix(file, initContext, nRows, nCols, Optional.of(false)) as DenseMatrix
  }
  
  @ProvidesFactory
  def static SparseMatrix parseSparseMatrix(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the col index (starting at 0), and the last is the value.") File file,
    @GlobalArg ObservationProcessor initContext,
    @ConstructorArg(value = "nRows") int nRows,
    @ConstructorArg(value = "nCols") int nCols
  ) {
    return parseMatrix(file, initContext, nRows, nCols, Optional.of(true)) as SparseMatrix
  }
  
  @ProvidesFactory
  def static Simplex parseSimplex(
    @ConstructorArg(value = "file", description = "CSV file where the first entry is the row index (starting at 0), the second is the value. Include the redundant one.") File file,
    @GlobalArg ObservationProcessor initContext,
    @ConstructorArg(value = "nRows") int nRows,
    @ConstructorArg(value = "nCols") int nCols
  ) {
    val DenseMatrix m = parseDenseMatrix(file, initContext, nRows, nCols)
    return StaticUtils::simplex(m)
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
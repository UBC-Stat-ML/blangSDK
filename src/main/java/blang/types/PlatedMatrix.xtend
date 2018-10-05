package blang.types

import blang.core.RealVar
import java.util.Map
import xlinear.Matrix
import java.util.LinkedHashMap
import xlinear.DenseMatrix
import blang.types.internals.Query
import briefj.Indexer
import com.rits.cloning.Immutable
import blang.runtime.internals.objectgraph.SkipDependency
import blang.runtime.Observations
import xlinear.MatrixOperations
import blang.types.internals.RealScalar
import blang.runtime.internals.objectgraph.MatrixConstituentNode
import blang.inits.DesignatedConstructor
import blang.inits.ConstructorArg
import blang.types.internals.ColumnName
import java.util.Optional
import blang.io.DataSource
import blang.io.internals.GlobalDataSourceStore
import blang.inits.GlobalArg
import blang.inits.InitService
import blang.inits.parsing.QualifiedName
import com.google.inject.TypeLiteral
import blang.inits.Creator

class PlatedMatrix {
  val Map<Query, Matrix> variables = new LinkedHashMap
  
  @SkipDependency(isMutable = false)
  val Observations observations
  var EnclosedPlated enclosed
  
  new (Observations observations, EnclosedPlated enclosed) {
    this.observations = observations
    this.enclosed = enclosed
  } 
  
  def entries() {
    return variables.entrySet
  }
  
  def DenseTransitionMatrix getDenseTransitionMatrix(Plate rowPlate, Plate colPlate, Index ... parentIndices) {
    return new DenseTransitionMatrix(getDenseMatrix(1.0 / colPlate.indices(parentIndices).size, rowPlate, colPlate, parentIndices))
  }
  
  def DenseSimplex getDenseSimplex(Plate rowPlate, Index ... parentIndices) {
    return new DenseSimplex(getDenseMatrix(1.0 / rowPlate.indices(parentIndices).size, rowPlate, null, parentIndices))
  }
  
  def DenseMatrix getDenseVector(Plate rowPlate, Index ... parentIndices) {
    return getDenseMatrix(rowPlate, null, parentIndices)
  }
  
  def DenseMatrix getDenseMatrix(Plate rowPlate, Plate colPlate, Index ... parentIndices) {
    getDenseMatrix(0.0, rowPlate, colPlate, parentIndices)
  }
  
  def DenseMatrix getDenseMatrix(double defaultValue, Plate rowPlate, Plate colPlate, Index ... parentIndices) {
    check(rowPlate, colPlate)
    val Query query = Query::build(parentIndices)
    if (variables.containsKey(query)) {
      return variables.get(query) as DenseMatrix
    }
    val vector = colPlate === null
    val rowIndexer =                         buildIndexer(rowPlate, parentIndices);       enclosed.rowIndexers.put(query, rowIndexer)
    val colIndexer = if (vector) null else { buildIndexer(colPlate, parentIndices); }     enclosed.colIndexers.put(query, colIndexer) 
    
    val result = MatrixOperations::dense(rowIndexer.size, if (vector) 1 else colIndexer.size)
    val Index[] mergedIndices = newArrayOfSize(parentIndices.size + if (vector) 1 else 2)
    for (var int i = 0; i < parentIndices.size; i++)
      mergedIndices.set(i, parentIndices.get(i))
    for (_row : rowPlate.indices(parentIndices)) {
      val Index row = _row as Index
      val rowIndex = rowIndexer.o2i(row)
      mergedIndices.set(parentIndices.size, row)
      for (_col : if (vector) #[null] else colPlate.indices(parentIndices)) {
        val colIndex = if (vector) 0 else {
          val Index col = _col as Index
          mergedIndices.set(parentIndices.size + 1, col)
          colIndexer.o2i(col)
        }
        val parsed = enclosed.plated.get(mergedIndices)
        if (parsed instanceof RealScalar) {
          // latent
          result.set(rowIndex, colIndex, defaultValue)
        } else {
          // observed
          observations.markAsObserved(new MatrixConstituentNode(result, rowIndex, colIndex))
          result.set(rowIndex, colIndex, parsed.doubleValue)
        }
      }
    }
    // TODO: for optimization/consistency purpose, use same method as Parsers' read matrix stuff 
    //       to make matrix readonly if all entries are observed 
    //       (a bit more complicated, see Parsers for details)
    variables.put(query, result)
    return result
  } 
  
  def <S> RealVar getDenseSimplexEntry(Plate<S> rowPlate, Index<S> rowIndex, Index ... parentIndices) {
    val vector = getDenseSimplex(rowPlate, parentIndices)
    val Query query = Query::build(parentIndices)
    return ExtensionUtils::getRealVar(vector, rowIndexer(query).o2i(rowIndex))
  }
  
  def <S> RealVar getDenseVectorEntry(Plate<S> rowPlate, Index<S> rowIndex, Index ... parentIndices) {
    val vector = getDenseVector(rowPlate, parentIndices)
    val Query query = Query::build(parentIndices)
    return ExtensionUtils::getRealVar(vector, rowIndexer(query).o2i(rowIndex))
  }
  
  def <S,T> RealVar getDenseTransitionMatrixEntry(Plate<S> rowPlate, Index<S> rowIndex, Plate<T> colPlate, Index<T> colIndex, Index ... parentIndices) {
    val matrix = getDenseTransitionMatrix(rowPlate, colPlate, parentIndices)
    val Query query = Query::build(parentIndices)
    return ExtensionUtils::getRealVar(matrix, rowIndexer(query).o2i(rowIndex), colIndexer(query).o2i(colIndex)) 
  }
  
  def <S,T> RealVar getDenseMatrixEntry(Plate<S> rowPlate, Index<S> rowIndex, Plate<T> colPlate, Index<T> colIndex, Index ... parentIndices) {
    val matrix = getDenseMatrix(rowPlate, colPlate, parentIndices)
    val Query query = Query::build(parentIndices)
    return ExtensionUtils::getRealVar(matrix, rowIndexer(query).o2i(rowIndex), colIndexer(query).o2i(colIndex))    
  }
  
  def private Indexer buildIndexer(Plate plate, Index ... parentIndices) {
    val result = new Indexer
    for (item : plate.indices(parentIndices)) 
      result.addToIndex(item) 
    return result
  }
  
  private def check(Plate<?> row, Plate<?> col) {
    if (enclosed.row === null) {
      enclosed.row = row
      enclosed.col = col
    } else {
      if (enclosed.row != row || enclosed.col != col)
        throw new RuntimeException
    }
  }
  
  def Indexer<Index<?>> rowIndexer(Query query) {
    return enclosed.rowIndexers.get(query)
  }
  
  def Indexer<Index<?>> colIndexer(Query query) {
    return enclosed.colIndexers.get(query)
  }
  
  def Plate<?> rowPlate() {
    return enclosed.row
  }
  
  def Plate<?> colPlate() {
    return enclosed.col
  }
  
  @Immutable
  private static class EnclosedPlated {
    val Plated<RealVar> plated
    val Map<Query, Indexer> rowIndexers = new LinkedHashMap
    val Map<Query, Indexer> colIndexers = new LinkedHashMap
    var Plate<?> row
    var Plate<?> col
    new (Plated<RealVar> plated) { this.plated = plated }
  }
  
  @DesignatedConstructor
  def static PlatedMatrix parse(
    @ConstructorArg(value = "name", description = "Name of variable in the plate") Optional<ColumnName> name,
    @ConstructorArg("dataSource") DataSource dataSource,
    @GlobalArg GlobalDataSourceStore globalDataSourceStore,
    @InitService QualifiedName qualifiedName,
    @InitService Creator creator,
    @GlobalArg Observations observations
  ) {
    val TypeLiteral<Plated<RealVar>> typeLiteral = new TypeLiteral<Plated<RealVar>>() {}
    val plated = Plated::parse(name, dataSource, globalDataSourceStore, qualifiedName, typeLiteral, creator) 
    return new PlatedMatrix(observations, new EnclosedPlated(plated))
  }
}
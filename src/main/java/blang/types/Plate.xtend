package blang.types

import blang.types.internals.ColumnName
import blang.inits.DesignatedConstructor
import blang.inits.ConstructorArg
import blang.io.DataSource
import blang.inits.GlobalArg
import blang.inits.InitService
import com.google.inject.TypeLiteral
import blang.inits.parsing.QualifiedName
import blang.inits.Creator 
import java.util.Optional
import java.lang.reflect.ParameterizedType
import blang.types.internals.SimpleParser
import blang.types.internals.HashPlate
import blang.types.internals.SimplePlate
import blang.io.internals.GlobalDataSourceStore
import java.util.Collection
import com.rits.cloning.Immutable

/** in the following, K is the type indexing the replicates, typically an Integer or String. We assume these indices are not random variables. */
@Immutable
interface Plate<K> {
  
  /** Human-readable name for the plate, typically automatically extracted from a DataSource column name. */
  def ColumnName getName() 
  
  /** Get the indices available given the indices of the parent (enclosing) plates. */
  def Collection<Index<K>> indices(Index<?> ... parentIndices)
  
  def K parse(String string)
  
  def Index<K> index(K key) { 
    return new Index<K>(this, key)
  }
  
  // Builders
  
  /** a plate with indices 0, 1, 2, ..., size-1 */
  def static Plate<Integer> simpleIntegerPlate(ColumnName columnName, int size) {
    return new SimplePlate(columnName, (0 ..< size).toSet)
  }
  
  /** a plate with indices category_0, category_1, ... */
  def static Plate<String> simpleStringPlate(ColumnName columnName, int size) {
    return new SimplePlate(columnName, (0 ..< size).map[index | "category_" + index].toSet)
  }
  
  def static <T> Plate<T> simplePlate(ColumnName columnName, TypeLiteral<T> type, int size) {
    if (type.rawType == Integer) {
      return simpleIntegerPlate(columnName, size) as Plate<T>
    } else if (type.rawType == String) {
      return simpleStringPlate(columnName, size) as Plate<T>
    } else {
      throw new RuntimeException("Unable to create a simple plate of type " + type)
    }
  }
  
  /*
   * Parser automatically called by the inits infrastructure.
   *  
   * Parsing works as follows:
   * 1. If no DataSource is available, call simplePlate()
   * 2. Else use HashPlate
   * 
   * A DataSource is available if:
   * a) either a GlobalDataSource has been defined in the model, or a DataSource is provided for this Plate (the latter has priority if both present)
   * b) the DataSource has a column with name corresponding to the name given to the declared Plate variable
   */
  @DesignatedConstructor
  def static <T> Plate<T> parse(
    @ConstructorArg("name") Optional<ColumnName> name,
    @ConstructorArg("maxSize") Optional<Integer> maxSize,
    @ConstructorArg("dataSource") DataSource dataSource,
    @GlobalArg GlobalDataSourceStore globalDataSourceStore,
    @InitService QualifiedName qualifiedName,
    @InitService TypeLiteral<T> typeLiteral,
    @InitService Creator creator 
  ) {
    val ColumnName columnName = name.orElse(new ColumnName(qualifiedName.simpleName()))
    val TypeLiteral<T> typeArgument = 
      TypeLiteral.get((typeLiteral.type as ParameterizedType).actualTypeArguments.get(0))
      as TypeLiteral<T>
    // data source
    var DataSource scopedDataSource = DataSource::scopedDataSource(dataSource, globalDataSourceStore)
    if (!scopedDataSource.present || !scopedDataSource.columnNames.contains(columnName)) {
      if (!maxSize.present) {
        throw new RuntimeException("Plates lacking a DataSource must specify a maxSize argument")
      }
      return simplePlate(columnName, typeArgument, maxSize.get)
    }
    return new HashPlate(columnName, scopedDataSource, new SimpleParser(creator, typeArgument), maxSize)
  }
}
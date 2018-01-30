package blang.types

import blang.inits.ConstructorArg
import blang.inits.Creator
import blang.inits.DesignatedConstructor
import blang.inits.GlobalArg
import blang.inits.InitService
import blang.inits.parsing.QualifiedName
import blang.io.DataSource
import blang.types.internals.ColumnName
import blang.types.internals.HashPlated
import blang.types.internals.PlatedSlice
import blang.types.internals.Query
import blang.types.internals.SimpleParser
import com.google.inject.TypeLiteral
import java.lang.reflect.ParameterizedType
import java.util.Map.Entry
import java.util.Optional
import blang.io.internals.GlobalDataSourceStore
import java.util.function.Supplier
import blang.types.internals.LatentFactoryAsParser
import java.util.Collection

/** a random variable or parameter of type T enclosed in one or more Plates. */
interface Plated<T>  {
  
  /** get the random variable or parameter indexed by the provided indices. The indices can be given in any order. */
  def T get(Index<?> ... indices) 
  // "Getting" may involve creating a new latent variable, a new observed variable, or just returning a previously created variable.
  
  /** list all variables obtained through get(..) so far. Each returned entry contains the variable as well as the associated indices (Query). */
  def Collection<Entry<Query, T>> entries()
  
  /** a view into a subset. */
  def Plated<T> slice(Index<?> ... indices) {
    return new PlatedSlice(this, Query::build(indices)) 
  }
  
  /** use the provided lambda expression to initialize several latent variables. */
  def static <T> Plated<T> latent(ColumnName name, Supplier<T> supplier) {
    return new HashPlated(name, DataSource::empty, new LatentFactoryAsParser(supplier))
  }
  
  def static <T> Plated<T> latent(String name, Supplier<T> supplier) {
    return latent(new ColumnName(name), supplier)
  }
  
  /*
   * Parser automatically called by the inits infrastructure. 
   * 
   * If a DataSource is available, the values will be parsed from the strings in that DataSource, otherwise,
   * all will be parsed via the string NA:SYMBOL.
   * 
   * A DataSource is available if:
   * a) either a GlobalDataSource has been defined in the model, or a DataSource is provided for this Plated (the latter has priority if both present).
   * b) the DataSource has a column with name corresponding to the name given to the declared Plated variable.
   */
  @DesignatedConstructor
  def static <T> Plated<T> parse(
    @ConstructorArg(value = "name", description = "Name of variable in the plate") Optional<ColumnName> name,
    @ConstructorArg("dataSource") DataSource dataSource,
    @GlobalArg GlobalDataSourceStore globalDataSourceStore,
    @InitService QualifiedName qualifiedName,
    @InitService TypeLiteral<T> typeLiteral,
    @InitService Creator creator 
  ) {
    val ColumnName columnName = name.orElse(new ColumnName(qualifiedName.simpleName()))
    // data source
    var DataSource scopedDataSource = DataSource::scopedDataSource(dataSource, globalDataSourceStore)
    if (scopedDataSource.present && !scopedDataSource.columnNames.contains(columnName)) {
      scopedDataSource = DataSource::empty
    }
    // parser
    val TypeLiteral<T> typeArgument = 
      TypeLiteral.get((typeLiteral.type as ParameterizedType).actualTypeArguments.get(0))
      as TypeLiteral<T>
    return new HashPlated(columnName, scopedDataSource, new SimpleParser(creator, typeArgument))
  }
}
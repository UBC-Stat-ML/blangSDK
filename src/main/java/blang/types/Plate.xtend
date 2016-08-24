package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Accessors
import blang.inits.DesignatedConstructor
import blang.inits.InitInfoType
import java.lang.reflect.Type
import blang.inits.InitInfoName
import blang.inits.QualifiedName
import blang.inits.Input
import java.lang.reflect.ParameterizedType
import java.util.List
import blang.runtime.objectgraph.SkipDependency
import java.util.LinkedHashSet
import java.util.ArrayList
import blang.types.Table.DataSource
import blang.inits.Instantiator.InstantiationContext
import blang.inits.InitInfoContext
import java.util.Collections
import java.util.HashMap
import java.util.Map

@Data
class Plate<K> {
  @Accessors(PUBLIC_GETTER)
  val Class<K> type
  
  @Accessors(PUBLIC_GETTER)
  val String columnName
  
  @SkipDependency
  val transient InstantiationContext context
  
  @SkipDependency
  var transient LinkedHashSet<Index<K>> _indicesCache = null
  
  @SkipDependency
  var transient Map<String, Index<K>> _parsingCache = new HashMap

  
  def LinkedHashSet<Index<K>> indices() {
    if (_indicesCache === null) {
      throw new RuntimeException("A plate should be initialized using contains(...)")
    }
    return _indicesCache
  }
  
  /**
   * Used in the init { ... } blocks to declare which tables are contained in the plate.
   */
  def void contains(Table<?> ... tables) { // TODO: abstract out Table? Other things might be in Plates.. just need getSourc
    // check not already initialized
    if (_indicesCache !== null) {
      throw new RuntimeException("contains(.., ..) should be called only once (use comma separated tables if there are many tables in the plate)")
    }
    
    // inform the tables in what they are contained too
    for (Table<?> table : tables) {
      table.enclosingPlates.add(this)
    }

    // find all tables with available datasource, and parse the keys
    val List<LinkedHashSet<Index<K>>> parsedKeysForEachAvailableDataSource = new ArrayList
    for (Table<?> table : tables) {
      if (table.source.present) {
        parsedKeysForEachAvailableDataSource.add(parseKeys(table.getSource().get))  
      }
    }
    
    // TODO: if it's empty and there is a limit statement, we're ok
    
    if (parsedKeysForEachAvailableDataSource.isEmpty()) {
      throw new RuntimeException("There is no way of inferring the keys in the plate") // TODO: more detail
    }
    
    // check the keys from all sources are all equal as sets
    val LinkedHashSet<Index<K>> result = parsedKeysForEachAvailableDataSource.get(0)
    for (var int i = 1; i < parsedKeysForEachAvailableDataSource.size(); i++) {
      if (result != parsedKeysForEachAvailableDataSource.get(i)) {
        throw new RuntimeException
      }
    }
    
    // TODO: use a limit statement to cut
    
    _indicesCache = result
  }
  
  def private LinkedHashSet<Index<K>> parseKeys(DataSource dataSource) {
    val LinkedHashSet<Index<K>> result = new LinkedHashSet
    for (String key : dataSource.keys(columnName)) {
      result.add(parseKey(key))
    }
    return result
  }
  
  def package Index<K> parseKey(String keyString) {
    if (_parsingCache.containsKey(keyString)) {
      return _parsingCache.get(keyString)
    }
    val K parsed = context.instantiateChild(
        type, 
        context.getChildArguments("_plate_index", Collections.singletonList(keyString)))
        .get // TODO: error handling
    val result = new Index<K>(this, parsed)
    _parsingCache.put(keyString, result)
    return result
  }
  
  def Index<K> index(K indexValue) {
    return new Index(this, indexValue)
  }
  
  @DesignatedConstructor
  def static <K> Plate<K> build(
    @InitInfoType Type plateType, 
    @InitInfoName QualifiedName qName,
    @Input(formatDescription = "Name of the plate, e.g. used to load the csv column (or empty to use name declared in blang file)") List<String> inputs,
    @InitInfoContext InstantiationContext initContext
  ) {
    val Class<K> type = (plateType as ParameterizedType).actualTypeArguments.get(0) as Class<K>
    val String inputName = inputs.join(" ")
    val String columnName = 
      if (inputName.isEmpty) {
        qName.simpleName()
      } else {
        inputName
      }
    return new Plate(type, columnName, initContext) 
  }
}
package blang.types

import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Accessors
import blang.inits.DesignatedConstructor
import blang.inits.InitInfoType
import java.lang.reflect.Type
import blang.inits.InitInfoName
import blang.inits.parsing.QualifiedName
import blang.inits.Input
import java.lang.reflect.ParameterizedType
import java.util.List
import blang.runtime.objectgraph.SkipDependency
import java.util.LinkedHashSet
import blang.types.Table.DataSource
import blang.inits.Instantiator.InstantiationContext
import blang.inits.InitInfoContext
import java.util.Collections
import java.util.HashMap
import java.util.Map
import java.util.Set

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
    if (!isInitialized()) {
      throw new RuntimeException("A plate should be initialized using contains(...)")
    }
    return _indicesCache
  }
  
  def boolean isInitialized() {
    return _indicesCache !== null
  }
  
  def void initialize(LinkedHashSet indices) {
    if (isInitialized()) {
      if (indices != _indicesCache) {
        throw new RuntimeException("Inconsistent specification of a plate, " + indices + " != " + _indicesCache)
      }
    } else {
      this._indicesCache = indices
    }
  }
  
  def LinkedHashSet<Index<K>> parseKeys(LinkedHashSet<String> keyStrings) {
    val LinkedHashSet<Index<K>> result = new LinkedHashSet
    for (String key : keyStrings) {
      result.add(parseKey(key))
    }
    return result
  }
  
  def package LinkedHashSet parseKeys(DataSource dataSource) {
    return parseKeys(dataSource.keys(columnName))
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
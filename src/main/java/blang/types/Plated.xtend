package blang.types

import java.util.Set
import java.util.Map
import java.util.List
import java.util.HashMap
import java.util.LinkedHashMap
import org.eclipse.xtend.lib.annotations.Data
import java.util.LinkedHashSet
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashSet
import blang.inits.Implementation
import blang.inits.DesignatedConstructor
import blang.inits.ConstructorArg
import java.io.File
import briefj.BriefIO
import java.util.ArrayList
import blang.inits.InitInfoType
import blang.inits.InitInfoName
import blang.inits.QualifiedName
import java.lang.reflect.Type
import java.lang.reflect.ParameterizedType
import blang.runtime.ObservationProcessor
import blang.inits.InitInfoContext
import blang.inits.Instantiator.InstantiationContext
import java.util.Collections
import java.util.Optional

@Implementation(TableImpl)
interface Plated<T> {
  
  def <K> Set<Index<K>> eachDistinct(Plate<K> plate)
  def T get(Index<?> ... indices)
  
  static class TableImpl<T> implements Plated<T> {
    
    val Class<T> platedType
    val String valueColumnName
    val InstantiationContext context

    @DesignatedConstructor
    new (
      @ConstructorArg("csvFile") File csvFile,
      @InitInfoContext InstantiationContext context  
    ) {
      this.context = context
      this.platedType = (context.requestedType as ParameterizedType).actualTypeArguments.get(0) as Class
      this.valueColumnName = context.qualifiedName.simpleName()
      val com.google.common.base.Optional<List<String>> fields = BriefIO.readLines(csvFile).splitCSV.first
      for (String name : fields.get) {
        column2RawData.put(name, new ArrayList)
      }
      for (Map<String,String> line : BriefIO.readLines(csvFile).indexCSV) {
        if (line.size != column2RawData.keySet.size) {
          throw new RuntimeException // TODO
        }
        for (String name : fields.get) {
          column2RawData.get(name).add(line.get(name))
        }
      }
    }
  
    // raw data
    val Map<String, List<String>> column2RawData = new LinkedHashMap
    
    // cache these sets to avoid looping each time an eachDistinct is called
    val Map<String, Set<String>> columnName2IndexValues = new LinkedHashMap
    
    // cache all queries
    val Map<String, Set<Index<?>>> _eachDistinct_cache = new HashMap
    val Map<GetQuery, Object> _get_cache = new HashMap
    
    // cache the parsed keys
    val Map<Pair<String,String>,Object> _columnAndString2ParsedObject = new HashMap
    
    def private Object getIndexCache(String columnName, String value) {
      return _columnAndString2ParsedObject.get(Pair.of(columnName, value))
    }
    
    def private void putInIndexCache(String columnName, String value, Object parsed) {
      _columnAndString2ParsedObject.put(Pair.of(columnName, value), parsed)
    }
    
    def private int rawSize() {
      if (column2RawData.size === 0) {
        return 0
      }
      return column2RawData.values.iterator.next.size
    }
    
    override <K> Set<Index<K>> eachDistinct(Plate<K> plate) {
      // check if in cache
      if (_eachDistinct_cache.containsKey(plate.columnName)) {
        return _eachDistinct_cache.get(plate.columnName) as Set
      }
      // compute if not
      var Set<Index<K>> result = new LinkedHashSet
      for (String indexValue : columnName2IndexValues.get(plate.columnName)) {
        
        val K parsed = context.instantiateChild(
          plate.type, 
          context.getChildArguments("_plate_index", Collections.singletonList(indexValue)))
          .get // TODO: error handling
        
        putInIndexCache(plate.columnName, indexValue, parsed)
        val Index<K> index = new Index(plate, parsed)
        result.add(index)
      }
      
      // insert into cache
      _eachDistinct_cache.put(plate.columnName, result as Set)
      
      return result
    }
    
    override T get(Index<?> ... indices) {
      val GetQuery query = GetQuery.build(indices)
      if (_get_cache.containsKey(query)) {
        return _get_cache.get(query) as T
      }
      // compute all cache entries if not
      for (var int dataIdx = 0; dataIdx < rawSize; dataIdx++) {
        val GetQuery curQuery = GetQuery.build
        for (Index<?> referenceIndex : indices) {
          val Plate curPlate = referenceIndex.plate
          val String curColumn = curPlate.columnName
          val String curIndexValue = column2RawData.get(curColumn).get(dataIdx)
          val Object parsed = getIndexCache(curColumn, curIndexValue)
          val Index curIndex = new Index(curPlate, parsed)
          curQuery.indices.add(curIndex)
        }
        if (_get_cache.containsKey(curQuery)) {
          throw new RuntimeException("More than one result for a given get(..) query")
        }
        
        val T parsedValue = context.instantiateChild(
          platedType, 
          context.getChildArguments("_table_value", Collections.singletonList(column2RawData.get(valueColumnName).get(dataIdx))))
          .get // TODO: error handling
        
        _get_cache.put(curQuery, parsedValue)
      }
      
      return _get_cache.get(query) as T
    }
    
    @Data // important! this is used in hash tables
    private static class GetQuery {
      val Set<Index<?>> indices
      def static GetQuery build(Index<?> ... indices) {
        return new GetQuery(new HashSet(indices))
      }

    }
  }
  
  @Data // important! this is used in hash tables
  static class Plate<K> {
    @Accessors(PUBLIC_GETTER)
    val Class<K> type
    
    @Accessors(PUBLIC_GETTER)
    val String columnName
    
    def Index<K> index(K indexValue) {
      return new Index(this, indexValue)
    }
    
    @DesignatedConstructor
    def static <K> Plate<K> build(
      @InitInfoType Type plateType, 
      @InitInfoName QualifiedName qName  
    ) {
      val Class<K> type = (plateType as ParameterizedType).actualTypeArguments.get(0) as Class<K>
      val String columnName = qName.simpleName()
      return new Plate(type, columnName)
    }
    
    
  }
  
  @Data // important! this is used in hash tables
  static class Index<K> {
    @Accessors(PUBLIC_GETTER)
    val Plate<K> plate
    
    @Accessors(PUBLIC_GETTER)
    val K value
  }

}
package blang.types

import blang.inits.DesignatedConstructor
import blang.inits.InitInfoContext
import blang.inits.Instantiator.InstantiationContext
import blang.runtime.objectgraph.SkipDependency
import briefj.BriefIO
import com.google.common.base.Joiner
import java.io.File
import java.lang.reflect.ParameterizedType
import java.util.ArrayList
import java.util.Collections
import java.util.HashMap
import java.util.LinkedHashMap
import java.util.LinkedHashSet
import java.util.List
import java.util.Map
import java.util.Optional
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import blang.inits.Input
import java.util.Collection
import java.util.Comparator

class Table<T> {  // Note: do not make an interface; this breaks because the generic argument gets lost in @Implementation(..) strategy 
    
  @SkipDependency
  val Class<T> platedType
  
  @SkipDependency
  val String valueColumnName
  
  @SkipDependency
  val InstantiationContext context
  
  /**
   * There may not necessarily be a data source, e.g. for latent variables in a table.
   */
  @SkipDependency
  @Accessors(PUBLIC_GETTER)
  val Optional<DataSource> source
  
  // this one is driving dependencies!
  val Map<GetQuery, Object> _get_cache = new HashMap

  @DesignatedConstructor
  new (
    @Input(formatDescription = "Path to csv file or empty if latent") List<String> file, // TODO: refactor that
    @InitInfoContext InstantiationContext context  
  ) {
    this.context = context
    this.platedType = (context.requestedType as ParameterizedType).actualTypeArguments.get(0) as Class
    this.valueColumnName = context.qualifiedName.simpleName()
    
    this.source = if (file.isEmpty) {
      Optional.empty
    } else {
      val File csvFile = new File(file.join(" "))
      println('''Loaded «csvFile» for data in «platedType» «valueColumnName»''')
      Optional.of(DataSource.fromCSV(csvFile))
    }
  }
  
  def private String childVariableName(Collection<Index<?>> indices) {
    val List<String> nameElements = new ArrayList
    for (Index<?> index : indices) {
      nameElements.add(index.plate.columnName + "=" + index.value)
    }
    return Joiner.on("_").join(nameElements)
  }
  
  def private cacheFromDataSource(GetQuery query) {
    // compute all cache entries if not
    for (var int dataIdx = 0; dataIdx < source.get.nEntries; dataIdx++) {
      val GetQuery curQuery = GetQuery.build
      
      for (Index<?> referenceIndex : query.indices) {
        val Plate<?> curPlate = referenceIndex.plate
        val String curColumn = curPlate.columnName
        val String curIndexValue = source.get.entry(curColumn, dataIdx)
        val Index<?> curIndex = curPlate.parseKey(curIndexValue)
        curQuery.indices.add(curIndex)
      }
      if (_get_cache.containsKey(curQuery)) {
        throw new RuntimeException("More than one result for a given get(..) query")
      }
      
      val T parsedValue = context.instantiateChild(
        platedType, 
        context.getChildArguments(childVariableName(curQuery.indices), Collections.singletonList(source.get.entry(valueColumnName, dataIdx))))
        .get // TODO: error handling
      
      _get_cache.put(curQuery, parsedValue)
    }
  }
  
  def private void cacheFromLatent(GetQuery curQuery) {
    val T parsedValue = context.instantiateChild(
        platedType, 
        context.getChildArguments(childVariableName(curQuery.indices), Collections.singletonList(NA::SYMBOL)))
        .get // TODO: error handling
    _get_cache.put(curQuery, parsedValue)
  }
  
  def private T get(GetQuery query) {
    if (_get_cache.containsKey(query)) {
      return _get_cache.get(query) as T  
    }
    if (source.present) {
      cacheFromDataSource(query)
    } else {
      cacheFromLatent(query)
    }
    return _get_cache.get(query) as T
  }

  def T get(Index<?> ... indices) {
    val GetQuery query = GetQuery.build(indices)
    return get(query)
  }
  
  def List<T> getList(Plate<Integer> plateIndexingList, Index<?> ... otherIndices) {
    val int max = plateIndexingList.indices.stream.map[it.value].max(Comparator.naturalOrder()).orElse(0)
    val List<T> result = new ArrayList
    var GetQuery tempQuery = GetQuery.build(otherIndices)
    for (var int i = 0; i <= max; i++) {
      val Index<Integer> cur = plateIndexingList.index(i)
      tempQuery.indices.add(cur)
      result.add(get(tempQuery))
      tempQuery.indices.remove(cur)
    }
    return result
  }
  
  @Data // important! this is used in hash tables
  private static class GetQuery {
    @SkipDependency
    val LinkedHashSet<Index<?>> indices
    def static GetQuery build(Index<?> ... indices) {
      return new GetQuery(new LinkedHashSet(indices))
    }
  }
  
  static class DataSource {
    
    val Map<String, LinkedHashSet<String>> columnName2IndexValues = new LinkedHashMap 
    val Map<String, List<String>> column2RawData = new LinkedHashMap
    
    def static DataSource fromCSV(File csvFile) {
      return new DataSource => [
        val com.google.common.base.Optional<List<String>> fields = BriefIO.readLines(csvFile).splitCSV.first
        for (String name : fields.get) {
          column2RawData.put(name, new ArrayList)
          columnName2IndexValues.put(name, new LinkedHashSet)
        }
        for (Map<String,String> line : BriefIO.readLines(csvFile).indexCSV) {
          if (line.size != column2RawData.keySet.size) {
            throw new RuntimeException // TODO
          }
          for (String name : fields.get) {
            column2RawData.get(name).add(line.get(name))
            columnName2IndexValues.get(name).add(line.get(name))
          }
        }
      ]
    }
    
    def LinkedHashSet<String> keys(String columnName) {
      return columnName2IndexValues.get(columnName)
    }
    
    def int nEntries() {
      if (column2RawData.size === 0) {
        return 0
      }
      return column2RawData.values.iterator.next.size
    }
    
    def String entry(String columnName, int dataIndex) {
      return column2RawData.get(columnName).get(dataIndex)
    }
    
  }
}
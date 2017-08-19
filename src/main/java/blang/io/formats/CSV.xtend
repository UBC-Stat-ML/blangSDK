package blang.io.formats

import java.util.Map
import briefj.BriefIO
import au.com.bytecode.opencsv.CSVParser
import blang.inits.Arg
import blang.inits.DefaultValue
import java.util.Optional
import blang.io.DataSourceReader
import java.util.List
import com.google.common.collect.Iterables
import com.google.common.collect.FluentIterable
import java.util.Collections
import blang.types.internals.ColumnName
import com.google.common.collect.Maps

class CSV implements DataSourceReader {
  
  @Arg @DefaultValue(",")
  char   separator = ','
  
  @Arg @DefaultValue("\"")
  char   quotechar = "\""
  
  @Arg @DefaultValue("\\")
  char      escape = "\\"
  
  @Arg    @DefaultValue("false")
  boolean strictQuotes = false
  
  @Arg               @DefaultValue("true")
  boolean ignoreLeadingWhiteSpace = true
  
  @Arg                                               
  Optional<Character> commentCharacter
  
  override Iterable<Map<ColumnName,String>> read(String path) {
    val fileIterator = BriefIO::readLines(path)
    val CSVParser parser = new CSVParser(
      separator, 
      quotechar, 
      escape, 
      strictQuotes, 
      ignoreLeadingWhiteSpace
    )
    val commentChar = commentCharacter.orElse(null)
    val List<ColumnName> keys = Iterables.getFirst(fileIterator.splitCSV(parser, commentChar), Collections.EMPTY_LIST).map[String key | new ColumnName(key)]
    val FluentIterable<List<String>> bodyIterable = fileIterator.splitCSV(parser, commentChar).skip(1)
    return bodyIterable.transform[List<String> values |
      val int size = keys.size()
        if (size != values.size())
          throw new RuntimeException("The number of keys should have the same length as the number of values:" + size + " vs " + values.size());
        val Map<ColumnName,String> result = Maps.newLinkedHashMap();
        for (var int i = 0; i < size; i++) {
          result.put(keys.get(i), values.get(i))
        }
        return result
    ]
  }
}
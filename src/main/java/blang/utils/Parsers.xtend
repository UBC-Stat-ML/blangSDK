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
import blang.types.IntVar.IntImpl
import blang.types.NA
import blang.types.BoolVar
import blang.types.BoolVar.BoolImpl
import blang.types.RealVar
import blang.types.RealVar.RealImpl

class Parsers {
  
  @ProvidesFactory
  def static RealVar parse(    
    @Input(formatDescription = "A number or NA (default is NA)") Optional<String> str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (!str.present || str.get == NA::SYMBOL) {
        new RealImpl(0.0)
      } else {
        initContext.markAsObserved(new RealImpl(Double.parseDouble(str.get)))
      }
  }
  
  @ProvidesFactory
  def static IntVar parseIntVar(
    @Input(formatDescription = "An integer or NA (default is NA)") Optional<String> str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (!str.present || str.get == NA::SYMBOL) {
        new IntImpl(0)
      } else {
        initContext.markAsObserved(new IntImpl(Integer.parseInt(str.get)))
      }
  }
  
  @ProvidesFactory
  def static BoolVar parseBoolVar(
    @Input(formatDescription = "true|false|NA (default is NA)") Optional<String> str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (!str.present || str.get == NA::SYMBOL) {
        new BoolImpl(false)
      } else {
        initContext.markAsObserved(new BoolImpl(
          if (str.get.toLowerCase == "true") {
            true
          } else if (str.get.toLowerCase == "false") {
            false
          } else {
            throw new RuntimeException("Invalid boolean string (should be 'true' or 'false' or 'NA'): " + str.get)
          }))
      }
  }
  
  
  
  @ProvidesFactory
  def static <T> List<T> parseList(
    @ConstructorArg(value = "file", description = "Each line will be an item in the list") File file,
    @InitService TypeLiteral<List<T>> actualType,
    @InitService Creator              creator
  ) {
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
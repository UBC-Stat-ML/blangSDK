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

class Parsers {
  
  @ProvidesFactory
  def static Matrix parseMatrix(
    @ConstructorArg(value = "file", description = "Each line will be an item in the list") File file
  ) {
    throw new RuntimeException // TODO
  }
  
    @ProvidesFactory
  def static Simplex parseSimplex(
    @ConstructorArg(value = "file", description = "Each line will be an item in the list") File file
  ) {
    throw new RuntimeException // TODO
  }
  
  @ProvidesFactory
  def static RealVar parseRealVar(    
    @Input(formatDescription = "A number or NA (default is NA)") Optional<String> str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (!str.present || str.get == NA::SYMBOL) {
        new RealScalar(0.0)
      } else {
        initContext.markAsObserved(new RealScalar(Double.parseDouble(str.get)))
      }
  }
  
  @ProvidesFactory
  def static IntVar parseIntVar(
    @Input(formatDescription = "An integer or NA (default is NA)") Optional<String> str,
    @GlobalArg ObservationProcessor initContext
  ) {
    return
      if (!str.present || str.get == NA::SYMBOL) {
        new IntScalar(0)
      } else {
        initContext.markAsObserved(new IntScalar(CoreProviders.parse_int(str.get)))
      }
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
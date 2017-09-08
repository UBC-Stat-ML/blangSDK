package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data
import blang.inits.Creator
import com.google.inject.TypeLiteral

@Data
public class SimpleParser<T> implements Parser<T> {
  val Creator creator
  val TypeLiteral<T> typeArgument 
  override parse(String string) {
    return creator.init(typeArgument, blang.inits.parsing.SimpleParser.parse(string))
  }
}
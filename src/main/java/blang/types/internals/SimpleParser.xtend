package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data
import blang.inits.Creator
import com.google.inject.TypeLiteral
import com.rits.cloning.Immutable

@Data
@Immutable
class SimpleParser<T> implements Parser<T> {
  val Creator creator
  val TypeLiteral<T> typeArgument 
  override parse(String string) {
    try {
      return creator.init(typeArgument, blang.inits.parsing.SimpleParser.parse(string))
    } catch (Exception e) {
      throw new RuntimeException("Failed to parse " + string + " as " + typeArgument) // removed details as creator.errorReport crashes if not yet initialized (i.e. crashed in SimpleParser.parse(..)) + ", details:\n" + creator.errorReport)
    }
  }
}
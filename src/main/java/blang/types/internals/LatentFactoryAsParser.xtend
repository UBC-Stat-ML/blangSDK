package blang.types.internals

import org.eclipse.xtend.lib.annotations.Data
import java.util.function.Supplier
import static extension blang.io.NA.isNA

@Data class LatentFactoryAsParser<T> implements Parser<T>  {
  
  val Supplier<T> supplier
  
  override parse(String string) {
    if (string.isNA) {
      return supplier.get
    } else {
      throw new RuntimeException
    }
  }
  
}
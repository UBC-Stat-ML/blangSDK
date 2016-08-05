package blang.runtime

import java.util.function.Supplier
import org.eclipse.xtend.lib.annotations.Data

@Data
class ConstantSupplier<T> implements Supplier<T> {
  
  val T value
  
  override T get() {
    return value
  }
  
}
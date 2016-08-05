package blang.runtime

import java.lang.annotation.Target
import java.lang.annotation.Retention

@Retention(RUNTIME)
@Target(TYPE)
annotation DefaultImplementation {
  Class<?> value
}
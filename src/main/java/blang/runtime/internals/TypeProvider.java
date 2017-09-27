package blang.runtime.internals;

import java.util.Collection;



public interface TypeProvider<P>
{
  public Collection<P> getProducts(Class<?> c);
}

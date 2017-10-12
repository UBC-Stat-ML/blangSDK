package blang.runtime.internals.objectgraph;


public class ObjectNode<T> implements Node
{
  public final T object;
  
  public ObjectNode(T object)
  {
    if (object == null)
      throw new RuntimeException();
    this.object = object;
  }
  
  @Override
  public int hashCode()
  {
    return System.identityHashCode(object);
  }
  
  @Override
  public String toString()
  {
    return "ObjectNode[class=" + object.getClass().getName() + ",objectId=" + System.identityHashCode(object) + "]";
  }
  
  @Override
  public String toStringSummary()
  {
    return "" + object.getClass().getName() + "@" + System.identityHashCode(object);
  }

  @Override
  public boolean equals(Object obj)
  {
    if (this == obj)
      return true;
    if (!(obj instanceof ObjectNode))
      return false;
    return ((ObjectNode<?>) obj).object == this.object;
  }

  @Override
  public boolean isMutable()
  {
    return false; // fields or array entries only are deemed mutable
  }
}
package blang.runtime.internals.objectgraph;

public abstract class ConstituentNode<K> implements Node
{
  /**
   * 
   * @return null if a primitive, the object referred to otherwise
   */
  public abstract Object resolve();
  
  public boolean resolvesToObject()
  {
    return resolve() != null;
  }
  
  // These should stay protected and without getter/setter 
  // Making them accessible is probably symptom of a bug, see e.g. commit b8c2f2f6df416c2d64527c373356965b1daec583
  protected final Object container;
  protected final K key;
  
  public ConstituentNode(Object container, K key)
  {
    if (container == null)
      throw new RuntimeException();
    this.container = container;
    this.key = key;
  }
  
  @Override
  public String toString()
  {
    return "ConstituentNode[containerClass=" + container.getClass() + ",containerObjectId=" + System.identityHashCode(container) + ",key=" + key + "]";
  }
  
  @Override
  public int hashCode()
  {
    final int prime = 31;
    int result = 1;
    result = prime * result
        + ((container == null) ? 0 : 
          // IMPORTANT distinction from automatically generated hashCode():
          // use identity hash code for the container (but not the key),
          // as e.g. large integer keys will not point to the same address
          System.identityHashCode(container));
    result = prime * result + ((key == null) ? 0 : key.hashCode());
    return result;
  }
  @Override
  public boolean equals(Object obj)
  {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (getClass() != obj.getClass())
      return false;
    @SuppressWarnings("rawtypes")
    ConstituentNode other = (ConstituentNode) obj;
    if (container == null)
    {
      if (other.container != null)
        return false;
    } else if (
        // IMPORTANT: see similar comment in hashCode()
        container != other.container)
        //!container.equals(other.container))
      return false;
    if (key == null)
    {
      if (other.key != null)
        return false;
    } else if (!key.equals(other.key))
      return false;
    return true;
  }
}
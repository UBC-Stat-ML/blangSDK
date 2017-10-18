package blang.runtime.internals.objectgraph;

public class NodeUtils 
{
  public static <T> Node get(T object)
  {
    if (object instanceof Node)
      return (Node) object;
    else
      return new ObjectNode<T>(object);
  }
  
  private NodeUtils() {}
}

package blang.runtime.internals.objectgraph;

import java.lang.reflect.Field;
import java.util.Iterator;
import java.util.List;

import briefj.ReflexionUtils;

public class StaticUtils  
{
  public static <T> Node node(T object)
  {
    if (object instanceof Node)
      return (Node) object;
    else
      return new ObjectNode<T>(object);
  }
  
  @SuppressWarnings("unchecked")
  public static <T> T tryCasting(Node node, Class<T> type)
  {
    // node instanceof type
    if (type.isAssignableFrom(node.getClass()))
      return (T) node;
    else if (node instanceof ObjectNode<?>)
    {
      ObjectNode<?> objectNode = (ObjectNode<?>) node;
      if (type.isAssignableFrom(objectNode.object.getClass()))
        return (T) objectNode.object;
    }
    return null;
  }
  
  public static List<Field> getDeclaredFields(Class<?> aClass)
  {
    List<Field> result = ReflexionUtils.getDeclaredFields(aClass, true);
    Iterator<Field> resultsIter = result.iterator();
    while (resultsIter.hasNext())
      if (resultsIter.next().getName().equals("$jacocoData")) // work around required for checking test-case coverage
        resultsIter.remove();
    return result;
  }
  
  private StaticUtils() {}
}

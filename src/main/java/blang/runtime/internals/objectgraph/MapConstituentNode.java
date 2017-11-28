package blang.runtime.internals.objectgraph;

import java.util.Map;

public class MapConstituentNode extends ConstituentNode<Object>
{
  public MapConstituentNode(Object container, Object key)
  {
    super(container, key);
  }

  @Override
  public Object resolve()
  {
    Map map = (Map) container;
    return map.get(key); 
  }
  
  @Override
  public String toStringSummary()
  {
    return "" + key;
  }

  @Override
  public boolean isMutable()
  {
    return true;
  }
}
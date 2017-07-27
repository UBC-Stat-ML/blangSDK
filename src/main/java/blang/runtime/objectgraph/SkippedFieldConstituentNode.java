package blang.runtime.objectgraph;

import java.lang.reflect.Field;



public class SkippedFieldConstituentNode extends ConstituentNode<Field> 
{
  public SkippedFieldConstituentNode(Object container, Field key)
  {
    super(container, key);
  }

  @Override
  public Object resolve()
  {
    return null;
  }

  @Override
  public boolean isMutable()
  {
    return true; // if it is skipped, it is to hide mutable stuff See Issue #62
  }
  
  @Override
  public String toStringSummary()
  {
    return key.getName();
  }
}
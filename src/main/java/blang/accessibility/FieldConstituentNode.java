package blang.accessibility;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;

import briefj.ReflexionUtils;



public class FieldConstituentNode extends ConstituentNode<Field> 
{
  public FieldConstituentNode(Object container, Field key)
  {
    super(container, key);
  }

  @Override
  public Object resolve()
  {
    if (key.getType().isPrimitive())
      return null;
    return ReflexionUtils.getFieldValue(key, container);
  }

  @Override
  public boolean isMutable()
  {
    return !Modifier.isFinal(key.getModifiers());
  }
  
  @Override
  public String toStringSummary()
  {
    return key.getName();
  }
}
package blang.runtime.internals.objectgraph;

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
    /*
     * If the field is skipped, it is to hide mutable stuff, so stating that 
     * the field is modifiable will have the correct behavior when doing recursive 
     * analysis of mutability. 
     * See Issue #62 in blang DSL project.
     */
    return true; 
  }
  
  @Override
  public String toStringSummary()
  {
    return key.getName();
  }
}
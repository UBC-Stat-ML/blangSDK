package blang.accessibility;



public class ArrayConstituentNode extends ConstituentNode<Integer>
{
  public ArrayConstituentNode(Object container, Integer key)
  {
    super(container, key);
  }

  @Override
  public Object resolve()
  {
    if (container.getClass().getComponentType().isPrimitive())
      return null;
    Object [] array = (Object[]) container;
    return array[key];
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
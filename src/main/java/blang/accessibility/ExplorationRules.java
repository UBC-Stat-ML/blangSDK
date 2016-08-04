package blang.accessibility;

import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import briefj.ReflexionUtils;



public class ExplorationRules
{
  public static List<ExplorationRule> defaultExplorationRules = Arrays.asList(
      ExplorationRules::arrayViews,
      ExplorationRules::arrays,
      ExplorationRules::knownImmutableObjects,
      ExplorationRules::standardObjects);
  
  public static List<ArrayConstituentNode> arrays(Object object)
  {
    Class<? extends Object> c = object.getClass();
    if (!c.isArray())
      return null;
    ArrayList<ArrayConstituentNode> result = new ArrayList<>();
    final int length = Array.getLength(object);
    for (int i = 0; i < length; i++)
      result.add(new ArrayConstituentNode(object, i));
    return result;
  }
  
  public static List<ArrayConstituentNode> arrayViews(Object object)
  {
    if (!(object instanceof ArrayView))
      return null;
    ArrayList<ArrayConstituentNode> result = new ArrayList<>();
    ArrayView view = (ArrayView) object;
    List<Field> annotatedDeclaredFields = ReflexionUtils.getAnnotatedDeclaredFields(view.getClass(), ViewedArray.class, true);
    if (annotatedDeclaredFields.size() != 1)
      throw new RuntimeException();
    Object array = ReflexionUtils.getFieldValue(annotatedDeclaredFields.get(0), view);
    for (int index : view.viewedIndices)
      result.add(new ArrayConstituentNode(array, index));
    return result;
  }
  
  public static List<? extends ConstituentNode<?>> knownImmutableObjects(Object object)
  {
    if (object instanceof String || 
        object instanceof Integer || 
        object instanceof Double || 
        object instanceof Boolean || 
        object instanceof Short ||
        object instanceof Long)
      return Collections.emptyList();
    else
      return null;
  }
  
  /**
   * Processes objects that are not arrays.
   * 
   * Processes fields (including those in the scope of anonymous objects as well as 
   * to outer class of a nested object) 
   * @param object
   * @return
   */
  public static List<FieldConstituentNode> standardObjects(Object object)
  {
    ArrayList<FieldConstituentNode> result = new ArrayList<>();
    
    // note: outer class and anonymous fields handled by the generated fields "x$y"
  
    // find all fields (including those of super class(es), recursively, if any
    for (Field f : ReflexionUtils.getDeclaredFields(object.getClass(), true))
      result.add(new FieldConstituentNode(object, f));
    
    return result;
  }
}

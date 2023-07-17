package blang.runtime.internals.objectgraph;

import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import com.rits.cloning.IFreezable;
import com.rits.cloning.Immutable;

import briefj.ReflexionUtils;
import xlinear.DenseMatrix;
import xlinear.Matrix;
import xlinear.SparseMatrix;
import xlinear.internals.Slice;



public class ExplorationRules
{
  public static List<ExplorationRule> defaultExplorationRules = Arrays.asList(
      ExplorationRules::arrayViews,
      ExplorationRules::arrays,
      // This rule was commented out in Oct 1st 2018 to resolve a corner case in nowellpack
      // However this introduces non-determinism in forward simulation (see commits around July 17 2023 in blang SDK and Pigeons.jl)
      // so reintroducing it. 
      ExplorationRules::maps,
      ExplorationRules::matrices,
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
  
  public static List<MapConstituentNode> maps(Object object)
  {
    if (!(object instanceof Map))
      return null;
    ArrayList<MapConstituentNode> result = new ArrayList<>();
    @SuppressWarnings("rawtypes")
    Map m = (Map) object;
    for (Object key : m.keySet())
      result.add(new MapConstituentNode(object, key));
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
  
  public static List<MatrixConstituentNode> matrices(Object object) 
  {
    if (!(object instanceof Matrix))
      return null;
    ArrayList<MatrixConstituentNode> result = new ArrayList<>();
    Matrix matrix = MatrixConstituentNode.findDelegate((Matrix) object);
    
    if (matrix instanceof Slice && ((Slice) matrix).isReadOnly())
      ; // If the matrix is read-only just skip
    else if (matrix instanceof SparseMatrix) 
      throw new RuntimeException("Sparse matrices not yet supported"); // TODO: solution is to not break into constituents?
    else if (matrix instanceof DenseMatrix)
      for (int r = 0; r < matrix.nRows(); r++) 
        for (int c = 0; c < matrix.nCols(); c++)
          result.add(new MatrixConstituentNode(matrix, r, c));
    else
      throw new RuntimeException();
    return result;
  }
  
  public static List<? extends ConstituentNode<?>> knownImmutableObjects(Object object)
  {
    if (object instanceof IFreezable)
      if (((IFreezable) object).isFrozen())
        return Collections.emptyList();
    if (object instanceof String || 
        object instanceof Integer || 
        object instanceof Double || 
        object instanceof Boolean || 
        object instanceof Short ||
        object instanceof Long ||
        object instanceof Class ||
        object.getClass().isAnnotationPresent(Immutable.class))
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
  public static List<ConstituentNode<?>> standardObjects(Object object)
  {
    ArrayList<ConstituentNode<?>> result = new ArrayList<>();
    
    // note: outer class and anonymous fields handled by the generated fields "x$y"
  
    // find all fields (including those of super class(es), recursively, if any
    for (Field f : StaticUtils.getDeclaredFields(object.getClass()))
      if (f.getAnnotation(SkipDependency.class) == null) 
        result.add(new FieldConstituentNode(object, f));
      else if (f.getAnnotation(SkipDependency.class).isMutable())
        result.add(new SkippedFieldConstituentNode(object, f));
      // and just skip altogether those with SkipDependency that are not mutable
    
    return result;
  }
}

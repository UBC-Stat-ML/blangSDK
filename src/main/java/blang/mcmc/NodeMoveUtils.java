package blang.mcmc;

import java.lang.reflect.Field;
import java.lang.reflect.ParameterizedType;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

import blang.factors.Factor;
import briefj.BriefCollections;
import briefj.BriefLists;
import briefj.ReflexionUtils;

import com.google.common.collect.Lists;


/**
 * Utilities for annotation-based instantiation of Samplers.
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 *
 */
public class NodeMoveUtils
{
  /**
   * An operator (move or proposal) specifies a list of factors that are 
   * expected to be connected to the variable that
   * this sampler is able to resample.
   * 
   * This checks if the list of factor found in 
   * a ProbabilityModel's variable's neighborhood 
   * match the operator's required fields, passed in fieldsToPopulate.
   * 
   * See assignFactorConnections() for the details of this matching process.
   * 
   * @param factors
   * @param fieldsToPopulate
   * @return
   */
  public static boolean isFactorAssignmentCompatible(
      List<? extends Factor> factors, 
      List<Field> fieldsToPopulate)
  {
    return assignFactorConnections(null, factors, fieldsToPopulate, true);
  }
  
  /**
   * Once the Operator is deemed to mach, it is instantiated, and 
   * a copy is passed in this method to fill (match) its fields with 
   * the factors in the ProbabilityModel, passed in fieldsToPopulate.
   * 
   * See assignFactorConnections() for the details of this matching process.
   * 
   * @param mcmcMoveInstance
   * @param factors
   * @param fieldsToPopulate
   */
  public static void assignFactorConnections(Operator mcmcMoveInstance, 
      List<? extends Factor> factors, 
      List<Field> fieldsToPopulate)
  {
    boolean result = assignFactorConnections(mcmcMoveInstance, factors, fieldsToPopulate, false);
    if (!result)
      throw new RuntimeException();
  }
  
  /**
   * 
   * Check or assign field matchings.
   * 
   * List the Operator's fields in the order specified by the comparator
   * fieldsComparator. For each one, iterator over the items in 
   * fieldsToPopulate (in the provided order) until the first factor
   * that match the field's type is found, or in case of a list, do this for
   * each factor matching the generic type bounds. 
   * 
   * Factors are actually copied into a fresh linked list, so that they can be
   * deleted as they are matched, to ensure the 1-1 property.
   * 
   * @param mcmcMoveInstance
   * @param factors
   * @param fieldsToPopulate
   * @param onlyPeek
   * @return true if all factors were successfully matched.
   */
  private static boolean assignFactorConnections(
      Operator mcmcMoveInstance, 
      List<? extends Factor> factors, 
      List<Field> fieldsToPopulate,
      boolean onlyPeek)
  {
    fieldsToPopulate = BriefLists.sort(fieldsToPopulate, fieldsComparator);
    factors = Lists.newLinkedList(factors);
    for (Field field : fieldsToPopulate)
      if (List.class.isAssignableFrom(field.getType()))
        assignListConnection(mcmcMoveInstance, field, factors, onlyPeek);
      else
        assignSingleConnection(mcmcMoveInstance, field, factors, onlyPeek);
    return factors.isEmpty();
  }
  
  private static void assignSingleConnection(Operator mcmcMoveInstance, Field field, List<? extends Factor> factors, boolean onlyPeek)
  {
    Iterator<? extends Factor> iterator = factors.iterator();
    while (iterator.hasNext())
    {
      Factor factor = iterator.next();
      if (field.getType().isAssignableFrom(factor.getClass()))
      {
        if (!onlyPeek)
          ReflexionUtils.setFieldValue(field, mcmcMoveInstance, factor);
        iterator.remove();
        return;
      }
    }
  }

  public static void assignVariable(Operator mcmcMoveInstance, Object variable)
  {
    Field field = getSampledVariableField(mcmcMoveInstance.getClass());
    ReflexionUtils.setFieldValue(field, mcmcMoveInstance, variable);
  }
  
  public static Field getSampledVariableField(Class<? extends Operator> moveType)
  {
    List<Field> matches = ReflexionUtils.getAnnotatedDeclaredFields(moveType, SampledVariable.class, true);
    if (matches.size() != 1)
      throw new RuntimeException("There should be exactly one @" + SampledVariable.class.getSimpleName() + " annotated field" +
          " in " + moveType);
    return BriefCollections.pick(matches);
  }

  private static void assignListConnection(Operator mcmcMoveInstance, Field field, List<? extends Factor> factors, boolean onlyPeek)
  {
    List<? super Factor> fieldList = onlyPeek ? null : Lists.newArrayList();
    if (!onlyPeek)
      ReflexionUtils.setFieldValue(field, mcmcMoveInstance, fieldList);
    Iterator<? extends Factor> iterator = factors.iterator();
    Class<?> genericType = getGenericType(field);
    while (iterator.hasNext())
    {
      Factor factor = iterator.next();
      
      if (genericType.isAssignableFrom(factor.getClass()))
      {
        if (!onlyPeek)
          fieldList.add(factor);
        iterator.remove();
      }
    }
  }

  /**
   * Order fields listing more specific types first (in terms of the 
   * type hierarchy), then lists of types (and ordering list by the more
   * specific type parameters first). Finally, break ties using the alphabetic
   * order of the names of the fields.
   */
  public static Comparator<Field> fieldsComparator = new Comparator<Field>() {

    @Override
    public int compare(Field f1, Field f2)
    {
      final Class<?> 
        t1 = getType(f1),
        t2 = getType(f2);
      final boolean 
        t2ExtendsT1 = t1.isAssignableFrom(t2),
        t1ExtendsT2 = t2.isAssignableFrom(t1);
      if (t2ExtendsT1 && t1ExtendsT2)
      {
        // if the two are of the same type, put non-list first
        final boolean 
          o1IsList = List.class.isAssignableFrom(f1.getType()),
          o2IsList = List.class.isAssignableFrom(f2.getType());
        if (o1IsList && !o2IsList)
          return 1;
        if (o2IsList && !o1IsList)
          return -1;
      }
      else
      {
        // enumerate most specific types first
        if (t2ExtendsT1)
          return 1;
        if (t1ExtendsT2)
          return -1;
      }
      // otherwise, sort in alphabetic order of field name
      return f1.getName().compareTo(f2.getName());
    }

    private Class<?> getType(Field field)
    {
      if (Factor.class.isAssignableFrom(field.getType())) 
        return field.getType();
      if (List.class.isAssignableFrom(field.getType()))
        return getGenericType(field);
      throw new RuntimeException("Fields annotated by @ConnectedFactor should be of type Factor or List: " + field);
    }
  };
  
  public static Class<?> getGenericType(Field field)
  {
    ParameterizedType genericType = (ParameterizedType) field.getGenericType();
    return (Class<?>) genericType.getActualTypeArguments()[0];
  }
}

package blang.annotations.util;

import java.lang.annotation.Annotation;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;


/**
 * getProduct(Class c) does the following:
 * 
 *   - check if c has annotation of type annotationType (A)
 *   - call the method named annotationMethod and collect the result, of type P (or P[] if isAnnotationMethodReturningAnArray = true)
 *   - recurse to the supertypes and interface and collect the list of all returned objects of type P
 *   
 * Confusingly, often used with P being itself a Class<SomeOtherType>
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 *
 * @param <A> Type of annotation
 * @param <P> Return type of one of the method of the annotation
 */
public class RecursiveAnnotationProducer<A extends Annotation,P> implements TypeProvider<P>
{
  private final Class<A> annotationType;
  private final Method annotationMethod;
  private final boolean isAnnotationMethodReturningAnArray;
  
  public static <A extends Annotation, P> RecursiveAnnotationProducer<A,P> ofClasses(
      Class<A> annotationType, 
      boolean isAnnotationMethodReturningAnArray)
  {
    return ofClasses(annotationType, isAnnotationMethodReturningAnArray, "value");
  }
  
  public static <A extends Annotation, P> RecursiveAnnotationProducer<A,P> ofClasses(
      Class<A> annotationType, 
      boolean isAnnotationMethodReturningAnArray,
      String methodName)
  {
    return new RecursiveAnnotationProducer<>(annotationType, Class.class, isAnnotationMethodReturningAnArray, methodName);
  }
  
  public RecursiveAnnotationProducer(
      Class<A> annotationType,
      Class<?> productType, 
      boolean isAnnotationMethodReturningAnArray,
      String methodName)
  {
    try { this.annotationMethod = annotationType.getDeclaredMethod(methodName); } 
    catch (Exception e) { throw new RuntimeException(e); }
    
    Class<?> check = annotationMethod.getReturnType();
    if (isAnnotationMethodReturningAnArray)
    {
      if (!check.getComponentType().equals(productType))
        throw new RuntimeException();
    }
    else
      if (!check.equals(productType))
        throw new RuntimeException();
    
    this.annotationType = annotationType;
    this.isAnnotationMethodReturningAnArray = isAnnotationMethodReturningAnArray;
  }
  
  private Map<Class<?>,List<P>> cache = new HashMap<>();
  
  public Collection<P> getProducts(Class<?> c)
  {
    if (cache.containsKey(c))
      return cache.get(c);
    
    List<A> annotations = getAnnotationsRecursively(c, annotationType);
    List<P> result = new ArrayList<P>();
    for (A annotation : annotations)
    {
      Object current;
      try { current = annotationMethod.invoke(annotation); }
      catch (Exception e) { throw new RuntimeException(e); }
          
      if (isAnnotationMethodReturningAnArray)
      {
        @SuppressWarnings("unchecked")
        P[] products = (P[]) current;
        result.addAll(Arrays.asList(products));
      }
      else
      {
        @SuppressWarnings("unchecked")
        P product = (P) current;
        result.add(product);
      }
    }
    cache.put(c, result.isEmpty() ? Collections.emptyList() : result);
    return result;
  }
  
  public static <A extends Annotation> List<A> getAnnotationsRecursively(Class<?> root, Class<A> a)
  {
    ArrayList<A> result = new ArrayList<A>();
    LinkedList<Class<?>> queue = new LinkedList<>();
    queue.add(root);
    HashSet<Class<?>> explored = new HashSet<>();
    explored.add(root);
    
    while (!queue.isEmpty())
    {
      Class<?> current = queue.poll();
      if (current.isAnnotationPresent(a))
        result.addAll(Arrays.asList(current.getAnnotationsByType(a)));
      
      Class<?> parent = current.getSuperclass();
      if (parent != null && !explored.contains(parent))
      {
        queue.add(parent);
        explored.add(parent);
      }
      
      for (Class<?> anInterface : current.getInterfaces())
        if (!explored.contains(anInterface))
        {
          queue.add(anInterface);
          explored.add(anInterface);
        }
    }
    return result;
  }
}
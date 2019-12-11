package blang.runtime.internals.objectgraph;

import com.rits.cloning.Cloner;

public class DeepCloner 
{
  public static final Cloner cloner = new Cloner(); // thread safe
    // cloner.nullTransient = true // not a good idea, Java SDK uses transient liberally e.g the data array in ArrayList!
    // override registerFastCloners() {} // not needed after all, but may want to add LinkedHashSet at some point
  
  public static <T> T deepClone(T object) 
  {
    return cloner.deepClone(object);
  }
}

package blang.runtime.internals.objectgraph;

import java.lang.annotation.Annotation;
import java.util.LinkedHashSet;
import java.util.Set;

import blang.core.SamplerTypes;
import blang.mcmc.Sampler;
import blang.mcmc.Samplers;
import blang.runtime.internals.RecursiveAnnotationProducer;

public class VariableUtils 
{
  public static boolean isVariable(Class<?> c)
  {
    for (Annotation a : c.getAnnotations())
      if (a instanceof Samplers ||
          a instanceof SamplerTypes)
        return true;
    return false;
  }
  
  @SuppressWarnings("unchecked")
  public static Set<Class<? extends Sampler>> annotatedSamplers(Class<?> latentNode)
  {
    Set<Class<? extends Sampler>> result = new LinkedHashSet<>();
    
    {
      RecursiveAnnotationProducer<Samplers, Class<? extends Sampler>> annotationsProducer = RecursiveAnnotationProducer.ofClasses(Samplers.class, true);
      result.addAll(annotationsProducer.getProducts(latentNode));
    }
    
    {
      @SuppressWarnings("rawtypes")
      RecursiveAnnotationProducer<Samplers, String> annotationsProducer = new RecursiveAnnotationProducer(SamplerTypes.class, String.class, true, "value");
      for (String fullyQual : annotationsProducer.getProducts(latentNode))
        try 
        { 
          @SuppressWarnings("rawtypes")
          Class opClass = Class.forName(fullyQual); 
          result.add(opClass);
        } 
        catch (Exception e) { throw new RuntimeException(e); }
    }
    
    return result;
  }
  
  private VariableUtils() {}
}

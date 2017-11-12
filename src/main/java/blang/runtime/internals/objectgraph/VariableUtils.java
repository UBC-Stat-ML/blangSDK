package blang.runtime.internals.objectgraph;

import java.lang.annotation.Annotation;
import java.util.LinkedHashSet;
import java.util.Set;

import blang.mcmc.Sampler;
import blang.mcmc.Samplers;
import blang.runtime.internals.RecursiveAnnotationProducer;

public class VariableUtils 
{
  public static boolean isVariable(Class<?> c)
  {
    for (Annotation a : c.getAnnotations())
      if (a instanceof Samplers)
        return true;
    return false;
  }
  
  public static Set<Class<? extends Sampler>> annotatedSamplers(Class<?> latentNode)
  {
    Set<Class<? extends Sampler>> result = new LinkedHashSet<>();
    RecursiveAnnotationProducer<Samplers, Class<? extends Sampler>> annotationsProducer = RecursiveAnnotationProducer.ofClasses(Samplers.class, true);
    result.addAll(annotationsProducer.getProducts(latentNode));
    return result;
  }
  
  private VariableUtils() {}
}

package blang.mcmc;

import java.lang.reflect.Field;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import blang.core.Factor;
import blang.core.SamplerTypes;
import blang.runtime.objectgraph.GraphAnalysis;
import blang.runtime.objectgraph.ObjectNode;
import blang.utils.RecursiveAnnotationProducer;
import blang.utils.TypeProvider;
import briefj.ReflexionUtils;



public class SamplerBuilder
{
  public static BuiltSamplers build(GraphAnalysis graphAnalysis)
  {
    return build(graphAnalysis, Collections.emptySet(), Collections.emptySet());
  }
  
  public static BuiltSamplers build(GraphAnalysis graphAnalysis, Set<Class<Sampler>> additionalSamplers, Set<Class<Sampler>> excludedSamplers)
  {
    BuiltSamplers result = new BuiltSamplers();
    for (ObjectNode<?> latent : graphAnalysis.getLatentVariables())
    {
      SamplerMatch current = new SamplerMatch(latent);
      // add samplers coming from Samplers annotations
      innerLoop:for (Class<? extends Sampler> product : SAMPLER_PROVIDER_1.getProducts(latent.object.getClass())) 
      {
        if (excludedSamplers.contains(product)) 
          continue innerLoop;
        Sampler o = tryInstantiate(product, latent, graphAnalysis);
        if (o != null)
          add(result, current, o);
      }
      
      // add samplers coming from SamplerTypes annotations
      innerLoop:for (String product : SAMPLER_PROVIDER_2.getProducts(latent.object.getClass()))
      {
        @SuppressWarnings("rawtypes")
        Class opClass = null;
        try { opClass = Class.forName(product); } catch (Exception e) { throw new RuntimeException(e); }
        if (excludedSamplers.contains(opClass)) 
          continue innerLoop;
        @SuppressWarnings("unchecked")
        Sampler o = tryInstantiate(opClass, latent, graphAnalysis);
        if (o != null)
          add(result, current, o);
      }
      
      // add sampler from additional list
      for (Class<Sampler> additionalSamplerClass : additionalSamplers)
        if (!excludedSamplers.contains(additionalSamplerClass)) 
        {
          Sampler o = tryInstantiate(additionalSamplerClass, latent, graphAnalysis);
          if (o != null) 
            add(result, current, o);
        }
      
      result.matchingReport.add(current);
    }
    return result;
  }
  
  private SamplerBuilder() {}
  
  private static void add(BuiltSamplers result, SamplerMatch match, Sampler product)
  {
    result.list.add(product);
    match.matchedSamplers.add(product.getClass());
  }
  
  public static <O extends Sampler> O tryInstantiate(
      Class<O> operatorClass, 
      ObjectNode<?> variable,
      GraphAnalysis graphAnalysis)
  {
    List<? extends Factor> factors = 
        graphAnalysis.getConnectedFactor(variable).stream()
          .map(node -> node.object)
          .collect(Collectors.toList());
    
    List<Field> fieldsToPopulate = ReflexionUtils.getAnnotatedDeclaredFields(operatorClass, ConnectedFactor.class, true);
    
    if (!NodeMoveUtils.isFactorAssignmentCompatible(factors, fieldsToPopulate))
      return null;
    
    // instantiate via empty constructor
    O instantiated = ReflexionUtils.instantiate(operatorClass);
    
    // fill the fields via annotations
    NodeMoveUtils.assignFactorConnections(instantiated, factors, fieldsToPopulate);
    
    // fill the variable node too; make sure there is only one such field
    NodeMoveUtils.assignVariable(instantiated, variable.object);
    
    // fill other injected variables
    NodeMoveUtils.assignGraphAnalysis(instantiated, graphAnalysis);
    
    if (instantiated instanceof Sampler) 
      if (!((Sampler) instantiated).setup())
        return null;
    
    return instantiated;
  }
  
  public static TypeProvider<Class<? extends Sampler>>  SAMPLER_PROVIDER_1 = RecursiveAnnotationProducer.ofClasses(Samplers.class, true);
  public static TypeProvider<String>                    SAMPLER_PROVIDER_2 = new RecursiveAnnotationProducer<>(SamplerTypes.class, String.class, true, "value");
  
}

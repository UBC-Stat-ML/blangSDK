package blang.mcmc.internals;

import java.lang.reflect.Field;
import java.util.List;
import java.util.stream.Collectors;

import blang.core.Factor;
import blang.core.SamplerTypes;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.Sampler;
import blang.mcmc.Samplers;
import blang.runtime.internals.RecursiveAnnotationProducer;
import blang.runtime.internals.TypeProvider;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.runtime.internals.objectgraph.Node;
import briefj.ReflexionUtils;



public class SamplerBuilder
{
  public static BuiltSamplers build(GraphAnalysis graphAnalysis)
  {
    return build(graphAnalysis, new SamplerBuilderOptions());
  }
  
  public static BuiltSamplers build(GraphAnalysis graphAnalysis, SamplerBuilderOptions options)
  {
    BuiltSamplers result = new BuiltSamplers();
    for (Node latentNode : graphAnalysis.getLatentVariables())
    {
      Object latent = GraphAnalysis.getLatentObject(latentNode);
      SamplerMatch current = new SamplerMatch(latent);
      // add samplers coming from Samplers annotations
      if (options.useAnnotation)
      {
        innerLoop:for (Class<? extends Sampler> product : SAMPLER_PROVIDER_1.getProducts(latent.getClass())) 
        {
          if (options.excluded.samplers.contains(product)) 
            continue innerLoop;
          Sampler o = tryInstantiate(product, latentNode, graphAnalysis);
          if (o != null)
            add(result, current, o, latentNode);
        }
      
      // add samplers coming from SamplerTypes annotations
        innerLoop:for (String product : SAMPLER_PROVIDER_2.getProducts(latent.getClass()))
        {
          @SuppressWarnings("rawtypes")
          Class opClass = null;
          try { opClass = Class.forName(product); } catch (Exception e) { throw new RuntimeException(e); }
          if (options.excluded.samplers.contains(opClass)) 
            continue innerLoop;
          @SuppressWarnings("unchecked")
          Sampler o = tryInstantiate(opClass, latentNode, graphAnalysis);
          if (o != null)
            add(result, current, o, latentNode);
        }
      }
      
      // add sampler from additional list
      for (Class<Sampler> additionalSamplerClass : options.additional.samplers)
        if (!options.excluded.samplers.contains(additionalSamplerClass)) 
        {
          Sampler o = tryInstantiate(additionalSamplerClass, latentNode, graphAnalysis);
          if (o != null) 
            add(result, current, o, latentNode);
        }
      
      result.matchingReport.add(current);
    }
    return result;
  }
  
  private SamplerBuilder() {}
  
  private static void add(BuiltSamplers result, SamplerMatch match, Sampler product, Node variable)
  {
    result.list.add(product);
    match.matchedSamplers.add(product.getClass());
    result.correspondingVariables.add(variable);
  }
  
  public static <O extends Sampler> O tryInstantiate(
      Class<O> operatorClass, 
      Node variable,
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
    NodeMoveUtils.assignVariable(instantiated, GraphAnalysis.getLatentObject(variable));
    
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

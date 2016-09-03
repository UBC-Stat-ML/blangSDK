package blang.mcmc;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
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
  public static TypeProvider<Class<? extends Operator>> SAMPLER_PROVIDER_1 = RecursiveAnnotationProducer.ofClasses(Samplers.class,     true);
  public static TypeProvider<String>                    SAMPLER_PROVIDER_2 = new RecursiveAnnotationProducer<>(SamplerTypes.class, String.class, true, "value");
  
  public static List<Sampler> instantiateSamplers(GraphAnalysis graphAnalysis)
  {
    List<Sampler> result = new ArrayList<Sampler>();
    for (ObjectNode<?> latent : graphAnalysis.latentVariables)
    {
      for (Class<? extends Operator> product : SAMPLER_PROVIDER_1.getProducts(latent.object.getClass()))
        if (Operator.class.isAssignableFrom(product))
        {
          Operator o = tryInstantiate(product, latent, graphAnalysis);
          if (o != null)
            result.add((Sampler) o);
        }
      
      for (String product : SAMPLER_PROVIDER_2.getProducts(latent.object.getClass()))
      {
        Class opClass = null;
        try { opClass = Class.forName(product); } catch (Exception e) { throw new RuntimeException(e); }
        Operator o = tryInstantiate(opClass, latent, graphAnalysis);
        if (o != null)
          result.add((Sampler) o);
      }
    }
    return result;
  }
  
  public static <O extends Operator> O tryInstantiate(
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
  
}

package blang.core;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import blang.accessibility.GraphAnalysis;
import blang.accessibility.ObjectNode;
import blang.factors.Factor;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.NodeMoveUtils;
import blang.mcmc.Operator;
import briefj.ReflexionUtils;



public class SamplerBuilder
{
  public static List<Sampler> instantiateSamplers(GraphAnalysis graphAnalysis)
  {
    List<Sampler> result = new ArrayList<Sampler>();
    for (ObjectNode<?> latent : graphAnalysis.latentVariables)
    {
      Collection<Class<? extends Operator>> products = graphAnalysis.typeProvider.getProducts(latent.object.getClass());
      for (Class<? extends Operator> product : products)
        if (Operator.class.isAssignableFrom(product))
        {
          Operator o = tryInstantiate(product, latent, graphAnalysis);
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
    
    return instantiated;
  }
  
}

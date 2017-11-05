package blang.mcmc.internals;

import java.lang.reflect.Field;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import blang.core.Factor;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.SampledVariable;
import blang.mcmc.Sampler;
import blang.mcmc.Samplers;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.runtime.internals.objectgraph.Node;
import blang.runtime.internals.objectgraph.VariableUtils;
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
    SamplerTypesMatcher typeMatcher = new SamplerTypesMatcher(options);
    for (Node latentNode : graphAnalysis.getLatentVariables())
    {
      Object latent = GraphAnalysis.getLatentObject(latentNode);
      SamplerMatch current = new SamplerMatch(latent);
      for (Class<? extends Sampler> typeMatch : typeMatcher.matches(latent.getClass()))
      {
        Sampler o = tryInstantiate(typeMatch, latentNode, graphAnalysis);
        if (o != null)
          add(result, current, o, latentNode);
      }
      result.matchingReport.add(current);
    }
    return result;
  }
  
  private static void add(BuiltSamplers result, SamplerMatch match, Sampler product, Node variable)
  {
    result.list.add(product);
    match.matchedSamplers.add(product.getClass());
    result.correspondingVariables.add(variable);
  }
  
  private static <O extends Sampler> O tryInstantiate(
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
    
    if (instantiated instanceof Sampler) 
      if (!((Sampler) instantiated).setup())
        return null;
    
    return instantiated;
  }
  
  /**
   * For internal use only. Use the SamplerMatch instead, which has the key difference that 
   * it takes into accound whether the factors were successfully matched as well (this cannot 
   * be determined from types alone).
   */
  private static class SamplerTypesMatcher
  {
    private final SamplerBuilderOptions options;
    private final Map<Class<?>, Set<Class<? extends Sampler>>> cache = new LinkedHashMap<>();
    
    public SamplerTypesMatcher(SamplerBuilderOptions options) {
      this.options = options;
    }

    public Set<Class<? extends Sampler>> matches(Class<?> latentNode)
    {
      if (cache.containsKey(latentNode))
        return cache.get(latentNode);
      
      Set<Class<? extends Sampler>> result = new LinkedHashSet<>();
      
      if (options.useAnnotation)
      {
        result.addAll(VariableUtils.annotatedSamplers(latentNode));
        result.removeAll(options.excluded.samplers);
        // check the samplers provided by annotations are compatible
        for (Class<? extends Sampler> samplerFromAnnotation : result)
          if (!isCompatible(samplerFromAnnotation, latentNode))
            throw new RuntimeException("Field marked by @" + SampledVariable.class.getSimpleName() + " is no assignable from " + latentNode.getSimpleName() + "\n" +
                "Ensure that you are properly linking the sampler types to variable types prescribed by annotations @" + SampledVariable.class.getSimpleName() + " and @" + Samplers.class.getSimpleName());
      }
      
      // add the additionals (checking they were not excluded) when assignable is ok
      for (Class<? extends Sampler> additional : options.additional.samplers)
        if (isCompatible(additional, latentNode))
          if (options.excluded.samplers.contains(additional))
            throw new RuntimeException("A sampler should not be both included and excluded: " + additional);
          else
            result.add(additional);
      
      cache.put(latentNode, result);
      return result;
    }
  }
  
  public static boolean isCompatible(Class<? extends Sampler> samplerType, Class<?> variableType)
  {
    Field variableField = NodeMoveUtils.getSampledVariableField(samplerType);
    return variableField.getType().isAssignableFrom(variableType);
  }
  
  private SamplerBuilder() {}
}

package blang.mcmc.internals;

import java.lang.reflect.Field;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import blang.core.Factor;
import blang.core.Model;
import blang.inits.experiments.ExperimentResults;
import blang.mcmc.ConnectedFactor;
import blang.mcmc.SampledVariable;
import blang.mcmc.Sampler;
import blang.mcmc.Samplers;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import blang.runtime.internals.objectgraph.Node;
import blang.runtime.internals.objectgraph.ObjectNode;
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
        Sampler o = tryInstantiate(typeMatch, latentNode, graphAnalysis, options.monitoringStatistics);
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
  
  private static Sampler tryInstantiate(
      Class<? extends Sampler> operatorClass, 
      Node variable,
      GraphAnalysis graphAnalysis,
      ExperimentResults monitoringResults)
  {
    List<? extends Factor> factors = 
        graphAnalysis.getConnectedFactor(variable).stream()
          .map(node -> node.object)
          .collect(Collectors.toList());
    
    List<Field> fieldsToPopulate = ReflexionUtils.getAnnotatedDeclaredFields(operatorClass, ConnectedFactor.class, true);
    
    if (!SamplerMatchingUtils.isFactorAssignmentCompatible(factors, fieldsToPopulate))
      return null;
    
    // instantiate via empty constructor
    Sampler instantiated = ReflexionUtils.instantiate(operatorClass);
    
    // if requested, skip fields defined under the sampled model (order matters, modifies factors in place)
    if (SamplerMatchingUtils.getSampledVariableField(operatorClass).getAnnotation(SampledVariable.class).skipFactorsFromSampledModel())
      skipFieldsDefinedUnderSampledModel(operatorClass, variable, graphAnalysis, factors);
    
    // fill the fields via annotations
    SamplerMatchingUtils.assignFactorConnections(instantiated, factors, fieldsToPopulate);
    
    // fill the variable node too; make sure there is only one such field
    SamplerMatchingUtils.assignVariable(instantiated, GraphAnalysis.getLatentObject(variable));
    
    SamplerBuilderContext context = new SamplerBuilderContext(graphAnalysis, variable, monitoringResults);
    if (!((Sampler) instantiated).setup(context))
      return null;
    context.tearDown();
    
    return instantiated;
  }
  
  // edits factors in place
  private static void skipFieldsDefinedUnderSampledModel(
      Class<? extends Sampler> operatorClass, 
      Node variable,
      GraphAnalysis graphAnalysis,
      List<? extends Factor> factors)
  {
    if (!(variable instanceof ObjectNode<?>) || !(((ObjectNode<?>) variable).object instanceof Model))
      throw new RuntimeException("The option skipFactorsFromSampledModel only applied when the sampled variable is a Model, "
          + "in: " + operatorClass.getSimpleName());
    Model model = (Model) ((ObjectNode<?>) variable).object;
    List<Factor> skippedFactorsList = graphAnalysis.factorsDefinedBy(model); 
    LinkedHashSet<ObjectNode<Factor>> skippedFactorSet = new LinkedHashSet<>();
    for (Factor skipped : skippedFactorsList)
      skippedFactorSet.add(new ObjectNode<>(skipped));
    Iterator<? extends Factor> iterator = factors.iterator();
    while (iterator.hasNext())
    {
      Factor current = iterator.next();
      if (skippedFactorSet.contains(new ObjectNode<>(current)))
        iterator.remove();
    }
  }
  
  /**
   * For internal use only. Use the SamplerMatch instead, which has the key difference that 
   * it takes into account whether the factors were successfully matched as well (this cannot 
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
    Field variableField = SamplerMatchingUtils.getSampledVariableField(samplerType);
    return variableField.getType().isAssignableFrom(variableType);
  }
  
  private SamplerBuilder() {}
}

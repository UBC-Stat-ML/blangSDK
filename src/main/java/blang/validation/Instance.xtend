package blang.validation

import blang.core.Model
import blang.mcmc.Sampler
import blang.mcmc.internals.BuiltSamplers
import blang.mcmc.internals.SamplerBuilder
import blang.mcmc.internals.SamplerBuilderOptions
import blang.runtime.Observations
import blang.runtime.SampledModel
import blang.runtime.internals.objectgraph.GraphAnalysis
import java.util.LinkedHashSet
import java.util.Set
import java.util.function.Function

class Instance<M extends Model> {
    public val M model
    public val Function<M, Double> [] testFunctions
    public val GraphAnalysis graphAnalysis
    public val BuiltSamplers allKernels
    public val SampledModel sampledModel
    new (M model, Function<M, Double> ... testFunctions) {
      this(model, new SamplerBuilderOptions(), testFunctions)
    }
    new (M model, SamplerBuilderOptions samplerOptions, Function<M, Double> ... testFunctions) {
      this.model = model
      this.testFunctions = testFunctions
      this.graphAnalysis = new GraphAnalysis(model, new Observations())
      this.allKernels = SamplerBuilder.build(graphAnalysis, samplerOptions)
      if (allKernels.list.isEmpty())
        throw new RuntimeException("No kernels produced by model to be tested")
      this.sampledModel = new SampledModel(graphAnalysis, allKernels);
    }
    def Set<Class<? extends Sampler>> samplerTypes() {
      val Set<Class<? extends Sampler>> samplerTypes = new LinkedHashSet()
      for (Sampler sampler : allKernels.list) {
        samplerTypes.add(sampler.getClass())
      }
      return samplerTypes       
    }
    def SampledModel restrictedSampledModel(Class<? extends Sampler> currentSamplerType) {
      val SamplerBuilderOptions options = SamplerBuilderOptions.startWithOnly(currentSamplerType)
      val BuiltSamplers currentKernel = SamplerBuilder.build(graphAnalysis, options)
      return new SampledModel(graphAnalysis, currentKernel)
    }
  }
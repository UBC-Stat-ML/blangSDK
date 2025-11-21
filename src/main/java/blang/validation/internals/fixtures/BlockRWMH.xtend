package blang.validation.internals.fixtures

import blang.mcmc.Sampler
import bayonet.distributions.Random
import blang.mcmc.SampledVariable
import blang.mcmc.ConnectedFactor
import java.util.List
import blang.core.LogScaleFactor
import xlinear.DenseMatrix
import xlinear.Matrix

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import blang.core.WritableRealVar
import blang.distributions.Generators
import org.apache.commons.math3.stat.descriptive.SummaryStatistics
import blang.mcmc.internals.SamplerBuilderContext
import blang.core.RealVar
import blang.inits.Arg
import java.io.File
import java.util.Optional

class BlockRWMH implements Sampler {
	
	@SampledVariable 
	Blocked<WritableRealVar> blocked
	
	@ConnectedFactor 
	List <LogScaleFactor> numericFactors 
	
	RealVar annealingParam
	
	SummaryStatistics rate = new SummaryStatistics
	
	override setup(SamplerBuilderContext context) {
		
		this.annealingParam = context.annealingParameter
		return true
	}
		
	override execute(Random rand) {
		execute(rand, blocked.chol.get(annealingParam.doubleValue))
	}
	
	def get() {
		val result = dense(blocked.variables.size)
		for (i : 0..<blocked.variables.size) {
			result.set(i, blocked.variables.get(i).doubleValue)
		}
		return result
	}
	
	def set(Matrix m) {
		for (i : 0..<blocked.variables.size) {
			blocked.variables.get(i).set(m.get(i))	
		}
	}
	
	def execute(Random random, Matrix chol_factor) {
		val variable = get()
		val log_density_before = logDensity(variable)
		val z = dense(variable.nEntries)
		for (i : 0..<variable.nEntries)
			z.set(i, random.nextGaussian) 
		val delta = chol_factor * z
		variable.addInPlace(delta) 
		val log_density_after = logDensity(variable)
		val ratio = Math.exp(log_density_after - log_density_before)
		if (!Double.isNaN(ratio) && Generators.bernoulli(random, Math.min(1.0, ratio))) {
			set(variable)
			rate.addValue(1.0)
		} else {
			variable.subInPlace(delta)
			set(variable)
			rate.addValue(0.0)
		}
//		if (rate.n > 0 && rate.n % 50 == 0) {
//			println("BlockRWMH accept rate = " + rate.mean)
//		}
	}
	
	def double logDensity(Matrix m) {
		set(m)
    	var sum = 0.0
    	for (LogScaleFactor f : numericFactors)
      		sum += f.logDensity();
    	return sum;
  	}
}
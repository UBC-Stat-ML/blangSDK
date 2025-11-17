package blang.validation.internals.fixtures

import xlinear.DenseMatrix
import org.eclipse.xtend.lib.annotations.Data
import blang.core.RealVar
import java.util.Collection
import blang.mcmc.Samplers
import java.util.List
import java.util.Optional
import blang.inits.Arg
import java.io.File
import xlinear.Matrix

import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*

@Samplers(BlockRWMH)
@Data
class Blocked<T> {
	val List<T> variables 
	val ProposalChol chol
	
	new(List<T> variables, String directory) {
		this.variables = variables 
		this.chol = new ProposalChol(directory, variables.size)
	}

}
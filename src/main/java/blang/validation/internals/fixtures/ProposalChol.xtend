package blang.validation.internals.fixtures

import blang.runtime.internals.objectgraph.DeepCloner
import java.util.List
import xlinear.DenseMatrix
import java.util.ArrayList
import briefj.BriefIO
import java.io.File


import static extension xlinear.MatrixExtensions.*
import static xlinear.MatrixOperations.*
import java.util.Arrays
import java.util.Collections
import briefj.BriefLog

class ProposalChol {
	List<DenseMatrix> chols
	List<Double> referenceAnnealingParams
	
	public static def void main(String[]  args) {
		val ref = Arrays.asList(0.0, 0.12, 0.44, 1.0)
		//							 0     1
		val tests = Arrays.asList(0.0, 0.1, 0.12, 0.2, 0.4, 0.44, 0.5, 1.0)
		for (test : tests) {
			println("processing " + test)
			println(index(test, ref))
			
		}
	}
	
	static def chol_index(int _index, int referenceAnnealingParams_size) {
		val chol_length = referenceAnnealingParams_size - 2 // no prior, no target
		val chol_last = chol_length - 1
		if (_index == 0)
			return 0 
		else if (_index == referenceAnnealingParams_size - 1)
			return chol_last // we don't keep proposal for target, use highest temperature
		else
			return _index - 1
	}
	
	static def index(double annealingParam, List<Double> referenceAnnealingParams) {
		val _index = Collections::binarySearch(referenceAnnealingParams, annealingParam)
		//println("_index=" + _index)
		if (_index >= 0) {
			chol_index(_index, referenceAnnealingParams.size)
		} else {
			val fixed_index = -_index - 1
			//println("fixed_index=" + fixed_index)
			// need to find what is closer, annealing param before or after? 
			val before = annealingParam - referenceAnnealingParams.get(fixed_index - 1)
			val after  = referenceAnnealingParams.get(fixed_index) - annealingParam
			if (before < after)
				chol_index(fixed_index - 1, referenceAnnealingParams.size) 
			else
				chol_index(fixed_index, referenceAnnealingParams.size) 
		}
		
//		BriefLog.warnOnce("called binarySearch with " + annealingParam + " got " + _index)
//		
//		val index = if (_index >= 0.0) 
//			_index 
//		else
//			- _index 
//			
//		val cholSize = referenceAnnealingParams.size - 2
//		val result = if (index >= cholSize) {
//			BriefLog.warnOnce("asked " + annealingParam + " got " + (referenceAnnealingParams.get(referenceAnnealingParams.size - 2)))
//			cholSize - 1
//		} else {
//			BriefLog.warnOnce("asked " + annealingParam + " got " + (referenceAnnealingParams.get(index + 1)))
//			index
//		}
//			
//		return result
	}
	
	def get(double annealingParam) {
		chols.get(index(annealingParam, referenceAnnealingParams))
	}
	
	new(String directory, int dim) {
		DeepCloner::cloner.registerImmutable(ProposalChol) 
		
		chols = new ArrayList()
		for (line : BriefIO.readLines(new File(directory, "chol_cov.txt")).skip(1)) {
			val matrix = dense(dim, dim)
			var i = 0 
			val rows = line.split("\\],\\s*\\[") 
			if (rows.size() !== dim)
				throw new RuntimeException("Row had length " + rows.size() + " but expected " + dim + " data: " + Arrays.toString(rows))
			for (_row : rows) {
				val row = _row.replace("[", "").replace("]", "") 
				val split_row = row.split("\\,\\s*") 
				if (split_row.size() !== dim) 
					throw new RuntimeException() 
				var j = 0
				for (entry : split_row) {
					matrix.set(i, j, Double.parseDouble(entry))
					j++
				}
				i++
			}
			chols.add(matrix.readOnlyView)
		}
		
		referenceAnnealingParams = new ArrayList() 
		for (exp : BriefIO.fileToString(new File(directory, "exponents.txt")).replace("[", "").replace("]", "").split(",\\s*")) {
			referenceAnnealingParams.add(Double.parseDouble(exp))
		} 
		
		if (chols.size + 2 != referenceAnnealingParams.size)
			throw new RuntimeException
		
		println("Loaded cholesky factors for proposals from " + directory)
		println("	for annealing params: " + referenceAnnealingParams)
	}
}
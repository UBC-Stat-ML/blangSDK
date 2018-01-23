package blang.mcmc

import java.util.List
import bayonet.distributions.Random
import blang.core.LogScaleFactor
import blang.distributions.Generators
import blang.distributions.NormalField
import blang.mcmc.internals.SamplerBuilderContext
import blang.types.Index
import blang.types.Precision
import briefj.Indexer
import xlinear.DenseMatrix
import xlinear.Matrix
import xlinear.MatrixOperations
import blang.core.WritableRealVar

class EllipticalSliceSampler<K> implements Sampler {
  
  @SampledVariable(skipFactorsFromSampledModel=true) 
  NormalField field
  
  @ConnectedFactor 
  List<LogScaleFactor> likelihoods
  
  int dim = -1
  Indexer<K> indexer = null
  Precision<K> precision = null

  override void execute(Random rand) {
    val DenseMatrix nu = MatrixOperations.sampleNormalByPrecision(rand, Precision.asMatrix(precision, indexer))
    val DenseMatrix current = getState()
    val double logSliceHeight = RealSliceSampler.nextLogSliceHeight(rand, logLikelihood())
    var double theta = Generators.uniform(rand, 0.0, 2.0 * Math.PI)
    var double leftProposalEndPoint = theta - 2.0 * Math.PI
    var double rightProposalEndPoint = theta
    while(true) {
      val DenseMatrix newState = current * Math.cos(theta) + nu * Math.sin(theta);
      if (logLikelihoodAt(newState) > logSliceHeight) {
        return;
      } else {
        if (theta < 0) {
          leftProposalEndPoint = theta;
        } else {
          rightProposalEndPoint = theta;
        }
        theta = Generators::uniform(rand, leftProposalEndPoint, rightProposalEndPoint)
      }
    }
  }

  def private DenseMatrix getState() {
    var DenseMatrix result = MatrixOperations.dense(dim)
    for (Index<K> index : precision.getPlate().indices())
      result.set(indexer.o2i(index.key), field.realization().get(index).doubleValue())
    return result
  }
  
  def private void setState(Matrix newState) {
    for (Index<K> index : precision.getPlate().indices())
      (field.getRealization().get(index) as WritableRealVar).set(newState.get(indexer.o2i(index.key)))
  }

  @SuppressWarnings("unchecked") 
  override boolean setup(SamplerBuilderContext context) {
    // TODO: check manually each latent entry in the field in latent
    precision = field.getPrecision()
    indexer = Precision.indexer(precision.getPlate())
    dim = indexer.size()
    return true
  }
  
  def private double logLikelihoodAt(Matrix point) {
    setState(point)
    return logLikelihood()
  }

  def private double logLikelihood() {
    var double sum = 0.0
    for (LogScaleFactor f : likelihoods)
      sum += f.logDensity()
    return sum
  }
}

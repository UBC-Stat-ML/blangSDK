package blang.algo;

public class ParallelTempering<P extends AnnealedParticle> 
{
  AnnealingKernels<P> kernels;
  
  /*
   * Questions:
   * - think about expansion to non-reversible?
   * - think about how SCM can initialize the ladder?
   * - think about perfect coupling argument based on exact simulation of zero-temperature chain
   */

  
  public void setKernels(AnnealingKernels<P> kernels)
  {
    this.kernels = kernels;
  }
}

package blang.mcmc

import java.util.List
import blang.core.LogScaleFactor
import blang.core.SupportFactor
import java.util.Random
import blang.types.Table
import blang.types.IntVar

class BaumWelch implements Sampler {
  
//  @SampledVariable MarkovModel model

  @SampledVariable
  private Table<IntVar> chain
  
  @ConnectedFactor
  protected List<SupportFactor> supportFactors;
  
  @ConnectedFactor
  protected List<LogScaleFactor> numericFactors;
  
  def boolean setup() {
    // TODO: make this called by the sampler architecture (perhaps add an interface, SamplerWithInit)
    
    // only applies if this is a chain of IntVars
    if (chain.platedType != IntVar ||
        chain.enclosingPlates.size() !== 1 || 
        chain.enclosingPlates.get(0).type != Integer
    ) {
      return false
    }
    
    // setup the graph 
    
    throw new RuntimeException
  }
  
  override void execute(Random rand) {
    
  }
  
}
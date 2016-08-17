package blang.runtime

import blang.inits.Instantiator
import blang.inits.Instantiators
import blang.inits.PosixParser
import blang.inits.strategies.FullyQualifiedImplementation
import blang.core.Model
import java.util.Optional
import blang.inits.Arg
import java.util.Random
import blang.inits.Default
import java.util.List
import blang.mcmc.Sampler
import java.util.Collections
import blang.types.Real

class Runner implements Runnable {
  
  @Arg 
  Model model
  
  @Arg @Default("1")
  Random random
  
  @Arg @Default("10 000")
  int nIterations
  
  def static void main(String [] args) {
    val Instantiator<Runner> instantiator = Instantiators.getDefault(Runner, PosixParser.parse(args))
    instantiator.strategies.put(Model, new FullyQualifiedImplementation)
    instantiator.debug = true
    val Optional<Runner> runner = instantiator.init  
    if (runner.present) {
      runner.get.run
    } else {
      println("Error(s) in provided arguments. Report:")
      println(instantiator.lastInitReport)
    }
  }
  
  override run() {
    var List<Sampler> samplers = ModelUtils.samplers(model) 
    for (var int i=0; i < nIterations; i++) {
      Collections.shuffle(samplers, random) 
      for (Sampler s : samplers) s.execute(random) 
      if ((i + 1) % 1_000 === 0) 
        System.out.println('''Iteration «(i + 1)»''') 
    }
  }
  
}
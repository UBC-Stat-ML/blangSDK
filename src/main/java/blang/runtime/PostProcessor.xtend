package blang.runtime

import blang.inits.Implementations
import blang.runtime.internals.DefaultPostProcessor
import blang.inits.experiments.Experiment
import blang.inits.Arg
import java.io.File
import java.util.Optional

@Implementations(DefaultPostProcessor, NoPostProcessor)
abstract class PostProcessor extends Experiment {
  
  @Arg(description = "When called from Blang, this will be the latest run, otherwise point to the .exec folder created by Blang")
  public Optional<File> blangExecutionDirectory 
  
  static class NoPostProcessor extends PostProcessor {
    override run() {
      System.out.println("No post-processing requested. Use '--postProcessor DefaultPostProcessor' or run after the fact using 'postprocess --help'")
    }
  }
  
}
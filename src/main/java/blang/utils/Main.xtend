package blang.utils

import binc.Command
import blang.runtime.Runner

class Main {

  def static void main(String[] args) {
    // compile 
    val StandaloneCompiler compiler = new StandaloneCompiler
    val String classpath = compiler.compile()
    
    // run
    println(classpath)
    var Command runnerCmd = Command.byName("java").withArg("-cp").withArg(classpath).withArg(Runner.typeName).withStandardOutMirroring()
    
    for (String arg : args) {
      runnerCmd = runnerCmd.withArg(arg)
    }
    Command.call(runnerCmd)
    runnerCmd.which
  }
  

  
}

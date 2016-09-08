package blang.utils

import binc.Command
import blang.runtime.Runner
import java.io.File

class Main {

  def static void main(String[] args) {
    // compile 
    val StandaloneCompiler compiler = new StandaloneCompiler
    val String classpath = compiler.compile()
    
    // run
    var Command runnerCmd = Command.byName("java").appendArg("-cp").appendArg(classpath).appendArg(Runner.typeName).withStandardOutMirroring()
    
    for (String arg : args) {
      runnerCmd = runnerCmd.appendArg(arg)
    }
    Command.call(runnerCmd)
    
    // hack: remove results/latest
    val File bad = new File("results/latest")
    bad.delete
  }
}

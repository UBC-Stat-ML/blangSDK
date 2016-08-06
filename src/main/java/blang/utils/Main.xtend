package blang.utils

import binc.Command
import blang.runtime.Runner
import java.util.List
import java.util.ArrayList
import com.google.common.base.Joiner

class Main {

  def static void main(String[] args) {
    // compile 
    val StandaloneCompiler compiler = new StandaloneCompiler
    val classpath = compiler.compile()
    
    // run
    println(classpath)
    var Command runnerCmd = Command.byName("java").withArg("-cp").withArg(classpath).withArg(Runner.typeName).withStandardOutMirroring()
    
    for (String arg : args) {
      runnerCmd = runnerCmd.withArg(arg)
    }
    Command.call(runnerCmd)
  }
  

  
}

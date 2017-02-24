package blang.utils

import binc.Command
import blang.runtime.Runner
import binc.Command.BinaryExecutionException

class Main {

  def static void main(String[] args) {
    // compile 
    val StandaloneCompiler compiler = new StandaloneCompiler
    val String classpath = try {
      compiler.compile()
    } catch (BinaryExecutionException bee) {
      System.err.println("Compilation error:")
      System.err.println(clean(bee.output.toString()))
      System.exit(1)
      throw new RuntimeException
    }
    
    // run
    var Command runnerCmd = 
      Command.byName("java")
        .appendArg("-cp").appendArg(classpath).appendArg(Runner.typeName)
        .withStandardOutMirroring()
    
    for (String arg : args) {
      runnerCmd = runnerCmd.appendArg(arg)
    }
    Command.call(runnerCmd)
  }
  
  def static String clean(String string) {
    val StringBuilder result = new StringBuilder
    for (String line : string.split("\n")) {
      if (line.contains("FAILED")) {
        return result.toString
      }
      result.append(line.replace(":generateXtextERROR:", "") + "\n")
    }
    return result.toString()
  }
  
}

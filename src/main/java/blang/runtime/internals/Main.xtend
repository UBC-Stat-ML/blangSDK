package blang.runtime.internals

import binc.Command.BinaryExecutionException
import java.io.File

class Main { // Warning: blang.runtime.internals.Main hard-coded in build.gradle

  def static void main(String[] args) {
    
    if (new File("build.gradle").exists) {
      System.err.println("It appears the folder already contains gradle build architecture. Use those instead of the blang command.")
      System.exit(1);
    }
    
    val StandaloneCompiler compiler = new StandaloneCompiler

    val String classpath = try {
      compiler.compileProject()
    } catch (BinaryExecutionException bee) {
      System.err.println("Compilation error(s):")
      System.err.println(clean(bee.output.toString()))
      exitWithError
      throw new RuntimeException
    } catch (Exception e) {
      System.err.println(e)
      exitWithError
      throw new RuntimeException
    }
    
    // run
    try {
      compiler.runCompiledModel(classpath, args)
    } catch (BinaryExecutionException bee) {
      // don't print: mirroring showed it already
      exitWithError
    } catch (Exception e) {
      System.err.println(e)
      exitWithError
      throw new RuntimeException
    }
  }
  
  def static void exitWithError() {
    System.out.flush
    System.err.flush
    System.exit(1)
  }
  
  def static String clean(String string) {
    val StringBuilder result = new StringBuilder
    for (String line : string.split("\n")) {
      if (line.startsWith("* What went wrong:"))
        return result.toString();
      if (!line.startsWith("WARNING:") && !line.startsWith("> Task"))
        result.append(line.replaceAll("[/].*[/]src[/]main[/]java[/]", "") + "\n") 
    }
    return result.toString()
  }
}

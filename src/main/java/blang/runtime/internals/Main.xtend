package blang.runtime.internals

import binc.Command.BinaryExecutionException
import java.io.File

class Main { // Warning: blang.runtime.internals.Main hard-coded in build.gradle

  val static infoMessage = '''
  
                         BLANG COMMAND LINE INTERFACE
  
  DESCRIPTION
  
    Blang is a language and software development kit for doing Bayesian analysis.
    See https://www.stat.ubc.ca/~bouchard/blang/ for documentation, including 
    alternative ways to use blang (graphical interface and gradle integration).
    
  BASIC USAGE
  
    To approximate the posterior distribution of a Bayesian model, follow these steps:
  
    - Create an empty project directory.
    - Create a file with a .bl extension in the project directory, say "Doomsday.bl".
    - Write a model in the Blang language in this file, for example:
        model Doomsday {
          random RealVar z
          random RealVar y
          param RealVar rate
          laws {
            z | rate ~ Exponential(rate)
            y | z ~ ContinuousUniform(0.0, z)
          }
        }
    - Call "blang --model Doomsday --model.rate 1.0 --model.y 1.2 --model.z NA" from 
      the root of the project directory.
    - The results can be found in "results/latest"
    
  OPTIONS
  
    A wide range of command line options are available, for example to select a different
    inference engine, tune inference, configure data input, select output format,  
    post-process the samples, etc. 
    
    To obtain a list of options, append "--help" to the command line call.
    
  DEPENDENCIES
  
    To import external packages and their transitive closures:
    
    - Create a file called "dependencies.txt" at the root of the project directory.
    - Each line in this file should specify a dependency in the format 
      "[group]:[artefact]:[version]"
    
  SUPPORTING FUNCTIONS, TYPES, SUBMODELS
  
    - All the files with extension .bl/.java/.xtend under the work directory are 
      compiled (incrementally).
    - For java files the file should be placed in a directory structure mirroring 
      the package. For example, a Java in package "my.pack" should be in 
      [project directory]/my/pack/File.java
      The same is not mandatory for xtend and bl files but we recommend to follow 
      this convention nonetheless. 
  '''

  def static void main(String[] args) {
    
    if (args.length === 0) {
      System.out.println(infoMessage)
      System.exit(1);
    }
    
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

package blang.runtime.internals

import binc.Command.BinaryExecutionException
import java.util.ArrayList

import blang.inits.experiments.Experiment

import blang.System
import java.nio.file.Files
import java.nio.file.Paths
import java.io.File
import briefj.BriefFiles
import briefj.BriefIO

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
    
    To obtain a list of options, append "--help" to the command line call. For commands
    specific to a model, append "--model modelName --help".
    
  DEPENDENCIES
  
    To import external packages and their transitive closures:
    
    - Create a file called "dependencies.txt" at the root of the project directory.
    - Each line in this file should specify a dependency in the format 
      "[group]:[artefact]:[version]"
    
  SUPPORTING FUNCTIONS, TYPES, SUBMODELS
  
    - All the files with extension .bl/.java/.xtend under the work directory are 
      compiled (incrementally).
    - For java files the file should be placed in a directory structure mirroring 
      the package. For example, a Java class named MyClass in package "my.pack" should be in 
      [project directory]/my/pack/MyClass.java
      This placement is not mandatory for xtend and bl files but we recommend to follow 
      this convention nonetheless. 
  '''


  def static void main(String[] args) {
  	
  	val boolean helpRequested = (args.length === 0 || (args.length === 1 && args.get(0) == "--help"))
    
    if (helpRequested) {
      System.out.println(infoMessage)
      System.exit(1); 
    }
    
    val boolean dirContainsGradle  = Files.walk(Paths.get(""))
                  .filter(f | !(f.startsWith(".blang-compilation")))
                  .anyMatch(f | f.endsWith("build.gradle"));
	
    if (dirContainsGradle) {
      System.err.println("It appears the (sub)folder(s) already contain gradle build architecture. Use those instead of the blang command.")
      System.exit(1);
    }
    
    val StandaloneCompiler compiler = try { 
      val result = new StandaloneCompiler
      result.init
      result
    } catch (Exception e) {
      Experiment::printException(e)
      exitWithError
      throw new RuntimeException
    }
    
    System.out.indentWithTiming("Compilation")

    System.out.println('''
      Note: this may take more time the first time the command is called
        as some dependencies will be downloaded.''')

    val String classpath = try {
      System.out.println("Using blang SDK version " + compiler.blangSDKVersion)
      compiler.compileProject()
    } catch (BinaryExecutionException bee) {
      System.err.indentWithTiming("Error")
      System.err.println("Compilation error report")
      val errorLog = bee.output.toString()
      System.err.println(clean(errorLog))
      val detailedErrors = new File("detailed-errors-" + System.currentTimeMillis + ".txt")
      BriefIO::stringToFile(detailedErrors, errorLog)
      System.err.println("Raw error output saved in: " + detailedErrors.absolutePath)
      System.err.popIndent
      exitWithError
      throw new RuntimeException
    } catch (Exception e) {
      Experiment::printException(e)
      exitWithError
      throw new RuntimeException
    } finally { System.out.popIndent }
    
    // run
    try {
      compiler.runCompiledModel(classpath, args)
    } catch (BinaryExecutionException bee) {
      // don't print: mirroring showed it already
      exitWithError
    } catch (Exception e) {
      Experiment::printException(e)
      exitWithError
      throw new RuntimeException
    } 
  }
  
  def static void exitWithError() {
    System.out.popAll
    System.out.flush
    System.err.flush
    System.exit(1)
  }
  
  def static String clean(String string) {
    val result = new ArrayList<String>
    
    for (String line : string.split("\n")) {
      if (line.startsWith("* What went wrong:"))
        return result.join("\n"); // cut the gradle rant
      if (!line.startsWith("WARNING:") && !line.startsWith("> Task") && !line.trim.empty) // Warnings seem always too misleading/irrelevant
        result.add(
          line.replaceAll("[/].*[/]src[/]main[/]java[/]", "")  // remove compilation folder from reported paths
        ) 
    }
    return result.join("\n")
  }
}

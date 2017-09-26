package blang.utils

import binc.Command.BinaryExecutionException
import blang.utils.internals.Versions
import java.util.Optional
import blang.inits.parsing.Arguments
import blang.runtime.Runner 
import blang.inits.Creators
import com.google.inject.TypeLiteral
import blang.utils.internals.Versions.BadVersion

class Main {

  def static void main(String[] args) {
    
    // read args to find version, if specified
    val Optional<String> requestedVersion = requestedVersion(args)
    
    // check that the tag is not too ancient (to avoid absorbing states)
    // TODO
    
    // TODO: test case to check integrity of git tag and build file
    
    // TODO Versions::updateIfNeeded should be aware of the version bounds? otherwise will print invalid tags!
    
    /*
     * TODO: change so that the repo is not actually changed, create a compilation pool instead
     * 
     * TODO: Versions::updateIfNeeded is inefficient in the sense that any run which is not calling the 
     * version produced by the call of installDist initially made by the user will result in starting a 
     * child process.. maybe that's ok?
     * 
     * TODO: Perhaps move to deamonized architecture?
     * 
     * TODO: can for sure do some caching: after compilation, keep the produced jar + list of paths for the 
     * gradle-cached dependencies
     */
     
    /*
     * TODO: use https://docs.gradle.org/current/userguide/embedding.html
     */
    
    // call Versions::updateIfNeeded(..)
    val StandaloneCompiler compiler = new StandaloneCompiler
    
    try {
      Versions::updateIfNeeded(requestedVersion, compiler.blangSDKRepository, compiler.getBlangRestarter(args))
    } catch (BinaryExecutionException bee) {
      // don't print: mirroring showed it already
      System.exit(1)
    } catch (BadVersion bv) {
      System.err.println(bv.message)
      System.exit(1)
    }
    
    println("Blang SDK version " + Versions::resolveVersion(requestedVersion, compiler.blangSDKRepository))
    
    val String classpath = try {
      compiler.compileProject()
    } catch (BinaryExecutionException bee) {
      System.err.println("Compilation error:")
      System.err.println(clean(bee.output.toString()))
      System.exit(1)
      throw new RuntimeException
    } catch (Exception e) {
      System.err.println(e)
      System.exit(1)
      throw new RuntimeException
    }
    
    // run
    try {
      compiler.runCompiledModel(classpath, args)
    } catch (BinaryExecutionException bee) {
      // don't print: mirroring showed it already
      System.exit(1)
    }
  }
  
  def static Optional<String> requestedVersion(String[] strings) {
    val Arguments parsed = Runner::parseArguments(strings)
    val Arguments subArg = parsed.child(Runner::VERSION_FIELD_NAME)
    val TypeLiteral<Optional<String>> optionalStringTypeLit
     = new TypeLiteral<Optional<String>>() {};
    return Creators::conventional.init(optionalStringTypeLit, subArg) 
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

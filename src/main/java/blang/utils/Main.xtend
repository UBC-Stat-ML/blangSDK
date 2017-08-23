package blang.utils

import binc.Command.BinaryExecutionException
import blang.utils.internals.Versions
import java.util.Optional
import blang.inits.parsing.Arguments
import blang.inits.parsing.Posix
import blang.runtime.Runner.Options import blang.inits.Creators
import com.google.inject.TypeLiteral
import blang.utils.internals.Versions.BadVersion

class Main {

  def static void main(String[] args) {
    
    // read args to find version, if specified
    val Optional<String> requestedVersion = requestedVersion(args)
    
    // check that the tag is not too ancient (to avoid absorbing states)
    // TODO
    
    // call Versions::updateIfNeeded(..)
    val StandaloneCompiler compiler = new StandaloneCompiler
    println(compiler.toString)
    
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
    
    println("1.0.36")
    
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
    compiler.runCompiledModel(classpath, args)
  }
  
  def static Optional<String> requestedVersion(String[] strings) {
    val Arguments parsed = Posix.parse(strings)
    val Arguments subArg = parsed.child(Options::VERSION_FIELD_NAME)
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

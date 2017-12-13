package blang.runtime.internals.doc

import blang.runtime.internals.doc.components.DocElement
import blang.runtime.internals.doc.components.Code
import java.io.File
import blang.runtime.internals.doc.components.Code.Language
import briefj.BriefIO
import briefj.repo.RepositoryUtils
import java.util.function.Function

class DocElementExtensions {

  def static void code(DocElement element, Class<?> code) { 
    element += loadCode(code, null)
  } 
  
  /**
   * Use to remove package declaration line
   */
  def static void code(DocElement element, Class<?> code, Function<String,String> transform) { 
    element += loadCode(code, transform)
  } 
  
  def private static Code loadCode(Class<?> code, Function<String,String> transform) {
    if (findFile(code, "bl")   !== null) return new Code(Language.blang, readSource(findFile(code, "bl"), transform))
    if (findFile(code, "java") !== null) return new Code(Language.java,  readSource(findFile(code, "java"), transform))
    throw new RuntimeException
  }
  
  def private static String readSource(File file, Function<String,String> transform) {
    var String contents = BriefIO.fileToString(file)
    if (transform !== null)
      contents = transform.apply(contents)
    return contents
  }
  
  def private static File findFile(Class<?> code, String ext) {
    val File repoRoot = findRepositoryRoot(code)
    val File file = new File(repoRoot, "src/main/java/" + code.name.replace(".", "/") + "." + ext)
    return if (file.exists) file else null
  }
  
  def private static File findRepositoryRoot(Class<?> code) {
    return new File(RepositoryUtils::findRepository(findSourceDir(code)).localAddress)
  }
  
  def private static File findSourceDir(Class<?> code) 
  {
    try { return new File(code.getProtectionDomain().getCodeSource().getLocation().toURI().getPath()); } 
    catch (Exception e) { throw new RuntimeException(e); }
  }
 
  private new() {}

}
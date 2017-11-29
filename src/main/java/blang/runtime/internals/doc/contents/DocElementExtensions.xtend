package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.DocElement
import blang.runtime.internals.doc.components.Code
import java.io.File
import blang.runtime.internals.doc.components.Code.Language
import briefj.BriefIO
import briefj.repo.RepositoryUtils

class DocElementExtensions {

  def static Code code(DocElement element, Class<?> code) { 
    val Code loadedCode = loadCode(code)
    element += loadedCode
    return loadedCode
  } 
  
  def private static Code loadCode(Class<?> code) {
    if (findFile(code, "bl")   !== null) return new Code(Language.blang, BriefIO.fileToString(findFile(code, "bl")))
    if (findFile(code, "java") !== null) return new Code(Language.java,  BriefIO.fileToString(findFile(code, "java")))
    throw new RuntimeException
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
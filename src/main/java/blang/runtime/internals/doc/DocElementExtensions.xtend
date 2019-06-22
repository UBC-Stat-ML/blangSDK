package blang.runtime.internals.doc

import blang.runtime.internals.doc.components.DocElement
import blang.runtime.internals.doc.components.Code
import java.io.File
import blang.runtime.internals.doc.components.Code.Language
import briefj.BriefIO
import briefj.repo.RepositoryUtils
import java.util.function.Function
import briefj.BriefStrings
import blang.runtime.internals.doc.components.MiniDoc

class DocElementExtensions {
  
  def static void documentClass(DocElement element, Class<?> type) {
    val Code code = loadCode(type, null)
    element += parse(type.simpleName, code.contents)
  }
  
  public var static boolean checkCommentsComplete = false
  def static MiniDoc parse(String name, String code) {
    var MiniDoc parent = null
    var String currentComment = null
    for (String line : code.split("\\R")) {
      if (line.contains("/**")) {
        currentComment = BriefStrings.firstGroupFromFirstMatch("[/][*][*](.*)", line).replaceAll("[*][/].*", "")
      } else if (currentComment !== null && !line.contains("*") && !line.matches("\\s*[@].*")) {
        if (parent === null) {
          parent = new MiniDoc(name, currentComment)
        } else {
          val String currentDecl = line.replace("public", "").replace("def", "").replace("override", "").replaceFirst("[{].*", "")
          val MiniDoc current = new MiniDoc(currentDecl.trim, currentComment)
          parent.children.add(current)
        }
        currentComment = null
      }
    }
    if (checkCommentsComplete && parent.children.empty || parent.doc === null)
      throw new RuntimeException("Incomplete documentation for: " + name)
    return parent
  }
  
  val public static GIT_RAW_SRC_URL = "https://raw.githubusercontent.com"
  def static void codeFromGit(DocElement element, Language language, String repoPath, String filePath) {
    val String path = #[GIT_RAW_SRC_URL, repoPath, filePath].join("/")
    element += new Code(language, BriefIO::urlToString(path))
  }
  
  // Workaround: importing files from test using usual method breaks gradle build, so using URL instead
  def static void codeFromBlangSDKRepo(DocElement element, Language language, String filePath) {
    DocElementExtensions::codeFromGit(element, language, "UBC-Stat-ML/blangSDK/master", filePath)
  }

  def static void code(DocElement element, Class<?> code) { 
    element += loadCode(code, null)
  } 
  
  /**
   * E.g. of use: removing package declaration line.
   */
  def static void code(DocElement element, Class<?> code, Function<String,String> transform) { 
    element += loadCode(code, transform)
  } 
  
  def private static Code loadCode(Class<?> code, Function<String,String> transform) {
    if (findFile(code, "bl")    !== null) return new Code(Language.blang,  readSource(findFile(code, "bl"), transform))
    if (findFile(code, "java")  !== null) return new Code(Language.java,   readSource(findFile(code, "java"), transform))
    if (findFile(code, "xtend") !== null) return new Code(Language.xtend,  readSource(findFile(code, "xtend"), transform))
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
    var File file = new File(repoRoot, "src/main/java/" + code.name.replace(".", "/") + "." + ext)
    // Note: do not look into test directory; when used this will break xtext's gradle build
    //    if (file.exists) return file
    //    file = new File(repoRoot, "src/test/java/" + code.name.replace(".", "/") + "." + ext)
    return if (file.exists) file else null
  }
  
  def static File findRepositoryRoot(Class<?> code) {
    return new File(RepositoryUtils::findRepository(findSourceDir(code)).localAddress)
  }
  
  def private static File findSourceDir(Class<?> code) 
  {
    try { return new File(code.getProtectionDomain().getCodeSource().getLocation().toURI().getPath()); } 
    catch (Exception e) { throw new RuntimeException(e); }
  }
 
  private new() {}
}
package blang

import java.io.File
import org.junit.Rule
import org.junit.rules.TemporaryFolder
import org.junit.Test
import briefj.BriefIO
import blang.runtime.Runner
import binc.Command
import blang.runtime.internals.doc.DocElementExtensions
import org.junit.Assert


class TestStandaloneCompiler {
  
  @Rule
  public TemporaryFolder folder = new TemporaryFolder();
  
  @Test
  def void test() {
    val root = folder.newFolder
    
    val blangFile = new File(root, "MyModel.bl")
    BriefIO::write(blangFile, '''
      package pack
      import pack.child.Util
      import subdir.JavaFile
      model MyModel {
        laws {}
      }
    ''')
    val xtendFile = new File(root, "Util.xtend")
    BriefIO::write(xtendFile, '''
      package pack.child
      class Util {
        
      }
    ''')
    val subdir = new File(root, "subdir")
    val javaFile = new File(subdir, "JavaFile.java")
    BriefIO::write(javaFile, '''
      package subdir;
      public class JavaFile {
        
      }
    ''')
    
    compiler(root, "pack.MyModel").throwOnNonZeroReturnCode.call
    
    // try introducing an error
    BriefIO::write(blangFile, '''
      Chtulu
    ''')
    
    val errored = compiler(root, "pack.MyModel").call
    Assert::assertTrue(errored.contains("Chtulu"))
    Assert::assertTrue(errored.contains("ERROR"))
  }
  
  def Command compiler(File runDir, String modelName) {
    val repoRoot = DocElementExtensions::findRepositoryRoot(Runner)
    val blangCmd = repoRoot.toPath.resolve("build/install/blang/bin/blang").toFile
    return Command::byPath(blangCmd)
        .ranIn(runDir)
        .appendArg(modelName);
  }
}
package blang

import java.io.File
import org.junit.Rule
import org.junit.rules.TemporaryFolder
import org.junit.Test
import briefj.BriefIO
import blang.runtime.Runner
import binc.Command
import blang.xdoc.DocElementExtensions
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
      import conifer.*
      import static conifer.Utils.*
      import subdir.JavaFile
      model MyModel {
        param Integer i ?: {
          val UnrootedTree tree = null
          0
        }
        laws {}
      }
    ''')
    
    BriefIO::write(new File(root, "dependencies.txt"), '''
    ca.ubc.stat:conifer:2.0.4
    ''')
    
    BriefIO::write(new File(root, "Util.xtend"), '''
      package pack.child
      class Util {
        
      }
    ''')
    BriefIO::write(new File(new File(root, "subdir"), "JavaFile.java"), '''
      package subdir;
      public class JavaFile {
        
      }
    ''')
    
    compiler(root, "pack.MyModel").throwOnNonZeroReturnCode.call
    
    // try introducing an error
    BriefIO::write(blangFile, '''
      Cthulhu
    ''')
    
    val errored = compiler(root, "pack.MyModel").call
    Assert::assertTrue(errored.contains("Cthulhu"))
    Assert::assertTrue(errored.contains("ERROR"))
  }
  
  @Test
  def void testGradleFixType1() {
    val root = folder.newFolder
    
    val blangFile = new File(root, "MyModel.bl")
    BriefIO::write(blangFile, '''
      model MyModel { 
        random RealVar x ?: latentReal
        laws {
          x ~ Normal(0.0, 1.0)
        }
      }
    ''')
    
    compiler(root, "bad").call
    compiler(root, "MyModel").throwOnNonZeroReturnCode.call
  }
  
  @Test
  def void testGradleFixType2() {
    val root = folder.newFolder
    
    val blangFile = new File(root, "MyModel.bl")
    val f = '''
      model MyModel { 
        random RealVar x ?: latentReal
        laws {
          x ~ Normal(0.0, 1.0)
        }
      }
    '''
    BriefIO::write(blangFile, f)
    compiler(root, "MyModel").throwOnNonZeroReturnCode.call
    BriefIO::write(blangFile, f + " ")
    compiler(root, "MyModel").throwOnNonZeroReturnCode.call
  }
  
  def Command compiler(File runDir, String modelName) {
    val repoRoot = DocElementExtensions::findRepositoryRoot(Runner)
    val blangCmd = repoRoot.toPath.resolve("build/install/blang/bin/blang").toFile
    return Command::byPath(blangCmd)
        .ranIn(runDir)
        .appendArg(modelName);
  }
}
package blang.utils;

import java.io.File;

import briefj.repo.RepositoryUtils;
import briefj.run.Mains;
import briefj.run.Results;

public class StandaloneCompiler implements Runnable {
  
  File blangHome;
  File projectHome;
  File compilationFolder;
  
  final String [] args;
  
  public StandaloneCompiler(String [] args) {
    this.args = args;
  }
  
  void setupCompilationFile(File model /*, List<Substitution> subs */) {
    throw new RuntimeException("Under dev");
  }



  
  @Override
  public void run() {
    // TODO: document that the SDK must preserves its .git folder
    blangHome = new File(RepositoryUtils.findRepository(RepositoryUtils.findSourceFile(this)).getLocalAddress());
    projectHome = new File(".");
    compilationFolder = Results.getFolderInResultFolder(COMPILATION_DIR_NAME);
    setupCompilationFiles();
  }
  
  private void setupCompilationFiles() {
    
  }

  public static void main(String[] args) {
    Mains.instrumentedRun(new String[0], new StandaloneCompiler(args));
  }

  public static final String COMPILATION_DIR_NAME = "blang-compilation";
}

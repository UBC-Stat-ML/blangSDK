package blang.utils;

import java.io.File;
import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.PathMatcher;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;

import com.google.common.base.Joiner;

import binc.Command;
import briefj.BriefIO;
import briefj.BriefStrings;
import briefj.repo.RepositoryUtils;
import briefj.run.Results;

public class StandaloneCompiler  {
  
  private final File blangHome;
  private final File projectHome;
  private final File compilationFolder;
  private final File compilationPool;
  private final Path srcFolder;
  
  public StandaloneCompiler() {
    
    // TODO: document that the SDK must preserves its .git folder
    // TODO: change this to not depend on the .git stuff (seems to call bash and hence might not be portable to windows)
    this.blangHome = new File(RepositoryUtils.findRepository(RepositoryUtils.findSourceFile(this)).getLocalAddress());
    this.projectHome = new File(".");
    this.compilationFolder = Results.getFolderInResultFolder(COMPILATION_DIR_NAME);
    this.compilationPool = compilationFolder.getParentFile().getParentFile();
    this.srcFolder = Paths.get(compilationFolder.getPath(), "src", "main", "java");
    init();
  }
  
  /**
   * 
   * @return classpath-formatted list of jars created and depended by the compilation task
   */
  public String compile() {
    runGradle("build");
    return "" +
        parseClasspath(runGradle("printClasspath")) + // dependencies
        File.pathSeparator +                             
                                                      // plus newly compiled file:
        Paths.get(compilationFolder.getPath(), "build", "libs", COMPILATION_DIR_NAME + ".jar").toAbsolutePath();
  }
  
  
  private String runGradle(String gradleTaskName) {
    Command gradleCmd = Command.byName("gradle").withArg(gradleTaskName).ranIn(compilationFolder);
    return Command.call(gradleCmd);
  }
  
  private static String parseClasspath(String gradleOutput) {
    List<String> items = new ArrayList<>();
    for (String line : gradleOutput.split("\\r?\\n"))
      if (line.matches("^.*[.]jar\\s*$"))
        items.add(line.replaceAll("\\s+", ""));
    return Joiner.on(File.pathSeparator).join(items);
  }

  private void init() {
    
    try { 
      // TODO: detect if already have a gradle setup
      // TODO: later, use always same and symlink if possible to save time
      
      setupBuildFiles();
      Files.createDirectories(srcFolder);
      Files.walkFileTree(projectHome.toPath(), new FileTransferProcessor()); 
    }
    catch (Exception e) { throw new RuntimeException(e); }
  }
  
  private static final PathMatcher BLANG_MATCHER = FileSystems.getDefault().getPathMatcher("glob:**.bl");
  
  class FileTransferProcessor extends SimpleFileVisitor<Path> {
    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
      if (BLANG_MATCHER.matches(file)) {
        Path target = srcFolder.resolve(file.getFileName());
        Files.copy(file, target);
      }
      return FileVisitResult.CONTINUE;
    }

    @Override
    public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
      if (dir.normalize().equals(compilationPool.toPath().normalize())) {
        return FileVisitResult.SKIP_SUBTREE;
      } else {
        return FileVisitResult.CONTINUE;
      }
    }
  }

  String sdkVersion;
  private void setupBuildFiles() {
    final String buildFileName = "build.gradle";
    String buildFileContents = BriefIO.fileToString(new File(blangHome, buildFileName));
    // find version
    sdkVersion = processDirective(buildFileContents, Directive.EXTRACT_VERSION);
    // add blangSDK dependency
    buildFileContents = processDirective(buildFileContents, Directive.ADD_SDK_DEPENDENCY);
    // remove deployment info
    buildFileContents = processDirective(buildFileContents, Directive.TRIM);
    File generatedBuildFile = new File(compilationFolder, buildFileName);
    BriefIO.write(generatedBuildFile, buildFileContents);
  }
  
  private static enum Directive {
    EXTRACT_VERSION {
      @Override
      String process(String buildFileContents, String line, StandaloneCompiler compiler) {
        return BriefStrings.firstGroupFromFirstMatch(".*\"(.*)\".*", line);
      }
    },
    ADD_SDK_DEPENDENCY {
      @Override
      String process(String buildFileContents, String line, StandaloneCompiler compiler) {
        String depLine = "  compile group: 'ca.ubc.stat', name: 'blangSDK', version: '" + compiler.sdkVersion + "'";
        return buildFileContents.replace(line, depLine);
      }
    },
    TRIM {
      @Override
      String process(String buildFileContents, String line, StandaloneCompiler compiler) {
        int index = buildFileContents.indexOf(line);
        return buildFileContents.substring(0, index);
      }
    }
    ;
    abstract String process(String buildFileContents, String line, StandaloneCompiler compiler);
  }

  private String processDirective(String buildFileContents, Directive directive) {
    // find the line containing the directive
    String line = findDirectiveLine(buildFileContents, directive);
    return directive.process(buildFileContents, line, this);
  }

  private String findDirectiveLine(String buildFileContents, Directive directive) {
    for (String line : buildFileContents.split("\\r?\\n"))
      if (line.contains(directive.toString()))
        return line;
    throw new RuntimeException();
  }

  public static final String COMPILATION_DIR_NAME = "blang-compilation";
}

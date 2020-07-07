package blang.runtime.internals;

import java.io.File;
import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.nio.file.FileSystems;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.PathMatcher;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.io.FileUtils;
import org.eclipse.jgit.internal.storage.file.FileRepository;
import org.eclipse.jgit.lib.Repository;

import com.google.common.base.Joiner;

import binc.Command;
import binc.Command.BinaryExecutionException;
import blang.runtime.Runner;
import briefj.BriefIO;
import briefj.BriefStrings;
import briefj.repo.RepositoryUtils;
import briefj.run.Results;

/**
 * See Main.xtend for documentation.
 * 
 * Under the hood, this works as follows:
 * 
 * - Create, if it does not exists, an invisible compilation folder
 * - Populate this a minimum set of gradle files adapted from the blangSDK repo hosting this code
 * - Look for a folder called 'dependencies' 
 * - Sync the bl, java, and xtend files from the root of where the command is called, excluding 
 *   those in folder "results", "input", and the compilation folder. This also creates directories in 
 *   the compilation folder as needed.
 * - Call gradlew in the compilation folder
 * - Start a new java process for Runner with the newly compiled model.
 */
public class StandaloneCompiler  {
  
  public final File blangHome;
  private final File projectHome;
  private final File compilationFolder;
  private final File excludedInputFolder; // in web ide, if an input node is itself in Blang, we want to avoid compiling it again
  private final Path srcFolder;
  private final List<String> dependencies = loadDependencies();
  
  public final String projectName; 
  public final String compilationDirName; 

  public StandaloneCompiler() {
    this("temporary", ".blang-compilation");
  }
  
  public StandaloneCompiler(String projectName, String compilationDirName) {
    this.projectName = projectName;
    this.compilationDirName = compilationDirName;
    this.blangHome = findBlangHome();
    this.projectHome = new File(".");
    this.compilationFolder = new File(compilationDirName);
    this.excludedInputFolder = new File(projectHome, "input");
    this.srcFolder = Paths.get(compilationFolder.getPath(), "src", "main", "java");
  }
  
  private List<String> loadDependencies() {
    List<String> result = new ArrayList<>();
    File dependencies = new File("dependencies.txt");
    Pattern depFormat = Pattern.compile("^[^:]+[:][^:]+[:][^:]+$");
    if (dependencies.exists())
      for (String line : BriefIO.readLines(dependencies)) {
        line = line.trim();
        if (line == null || line.isEmpty())
          continue;
        Matcher m = depFormat.matcher(line);
        if (m.find()) {
          result.add(line);
        } else {
          throw new RuntimeException("Invalid dependencies.txt format: " + line);
        }
      }
    return result;
  }

  @Override
  public String toString() {
    return 
      "Blang home folder: " + blangHome.getAbsolutePath() + "\n" +
      "Project folder: " + compilationFolder.getAbsolutePath();
  }

  File findBlangHome() {
    File file = RepositoryUtils.findSourceFile(this);
    while (!new File(file, BUILD_FILE).exists() && file.getParent() != null) {
      file = file.getParentFile();
    }
    if (new File(file, BUILD_FILE).exists()) {
      return file;
    } else {
      throw new RuntimeException("Blang home cannot be located.");
    }
  }
  
  public Repository getBlangSDKRepository() {
    try {
      return new FileRepository(new File(blangHome, ".git"));
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }
  
  final static String BUILD_FILE = "build.gradle";
  
  public String compileProject() {
    return compile(compilationFolder, projectName);
  }
  
  /**
   * 
   * @return classpath-formatted list of jars created or that the build task depends on
   */
  public static String compile(File folder, String projectName) throws BinaryExecutionException {
    runGradle("clean", folder);
    runGradle("assemble", folder);
    Path justCompiled = Paths.get(folder.getPath(), "build", "libs", projectName + ".jar");
    if (!Files.exists(justCompiled)) throw new RuntimeException("Not found: " + justCompiled);
    return "" +
        parseClasspath(runGradle("printClasspath", folder)) + // dependencies
        File.pathSeparator +                             
                                                      // plus newly compiled file:
        justCompiled.toAbsolutePath();
  }
  
  
  private static String runGradle(String gradleTaskName, File folder) throws BinaryExecutionException  {
    Command gradleCmd = 
        Command.byPath(new File(folder, "gradlew"))
          .appendArg(gradleTaskName)
          .appendArg("-Dorg.gradle.daemon.idletimeout=" + (1000*60*5)) // 5 minute time-out to make sure web ide does not get taxed too much memory-wise
          .ranIn(folder)
          .throwOnNonZeroReturnCode();
    return Command.call(gradleCmd);
  }
  
  public void runCompiledModel(String classpath, String [] args) {
    Command runnerCmd = javaCommand()
        .withStandardOutMirroring()
        .throwOnNonZeroReturnCode()
        .appendArg("-cp").appendArg(classpath)
        .appendArg(Runner.class.getTypeName());
    for (String arg : args) {
      runnerCmd = runnerCmd.appendArg(arg);
    }
    Command.call(runnerCmd);
  }
  
  public static Command javaCommand()
  {
    Command javaCmd = Command.byPath(Paths.get(System.getProperty("java.home"), "bin", "java").toFile());
    
    // get Xmx options such as -Xmx1g, etc
    for (String jvmArgument : ManagementFactory.getRuntimeMXBean().getInputArguments()) {
      javaCmd = javaCmd.appendArg(jvmArgument);
    }
    
    return javaCmd;
  }
  
  private static String parseClasspath(String gradleOutput) {
    List<String> items = new ArrayList<>();
    for (String line : gradleOutput.split("\\r?\\n"))
      if (line.matches("^.*[.]jar\\s*$"))
        items.add(line.replaceAll("\\s+", ""));
    if (items.isEmpty())
      throw new RuntimeException("Compilation infrastructure setup failed (could not form classpath of dependencies: \n" + gradleOutput);
    return Joiner.on(File.pathSeparator).join(items);
  }

  public void init() {
    try { 
      setupBuildFiles();
      
      // update
      Files.walkFileTree(projectHome.toPath(), new FileTransferProcessor(projectHome.toPath(), srcFolder));  
      // remove deleted
      Files.walkFileTree(srcFolder, new FileRemoveProcessor(projectHome.toPath(), srcFolder));
      // add a dummy xtend file to work around gradle/xtext bug 
      // set to commit 54c7aba5d9e1e067ce186a5f8761a528030e4f00 run https://github.com/UBC-Stat-ML/blangBugs, type1Dummer.sh vs. type1.sh
      BriefIO.write(new File(srcFolder.toFile(), "Dummy.xtend"), "class Dummy {}");
    }
    catch (Exception e) { throw new RuntimeException(e); }
  }
  
  private static final PathMatcher BLANG_MATCHER = FileSystems.getDefault().getPathMatcher("glob:**.{java,bl,xtend}");
  
  class FileTransferProcessor extends SimpleFileVisitor<Path> {
    final Path fromRoot, toRoot;
    public FileTransferProcessor(Path fromRoot, Path toRoot) {
      this.fromRoot = fromRoot;
      this.toRoot = toRoot;
    }
    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
      if (BLANG_MATCHER.matches(file)) {
        Path target = targetPath(file);
        if (!target.toFile().exists() || !FileUtils.contentEquals(target.toFile(), file.toFile()))
          Files.copy(file, target, StandardCopyOption.REPLACE_EXISTING);
      }
      return FileVisitResult.CONTINUE;
    }

    @Override
    public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
      if (dir.endsWith(compilationDirName) || 
          dir.endsWith(".git") ||
          dir.normalize().equals(fromRoot.resolve(Results.DEFAULT_POOL_NAME).normalize()) ||
          dir.normalize().equals(excludedInputFolder.toPath().normalize())) {
        return FileVisitResult.SKIP_SUBTREE;
      } else {
        File f = targetPath(dir).toFile();
        if (!f.exists())
          f.mkdir();
        return FileVisitResult.CONTINUE;
      }
    }
    
    private Path targetPath(Path file) {
      Path suffix = fromRoot.relativize(file);
      return toRoot.resolve(suffix);
    }
  }
  
  class FileRemoveProcessor extends SimpleFileVisitor<Path> {
    final Path fromRoot, toRoot;
    public FileRemoveProcessor(Path fromRoot, Path toRoot) {
      this.fromRoot = fromRoot;
      this.toRoot = toRoot;
    }
    @Override
    public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
      if (BLANG_MATCHER.matches(file)) {
        Path original = originalPath(file);
        if (!original.toFile().exists()) // no danger to delete added files as those are not java/bl/xtend
          Files.delete(file);
      }
      return FileVisitResult.CONTINUE;
    }
    
    private Path originalPath(Path file) {
      Path suffix = toRoot.relativize(file);
      return fromRoot.resolve(suffix);
    }
  }
  
  public String blangSDKVersion() {
    String buildFileContents = BriefIO.fileToString(new File(blangHome, BUILD_FILE));
    return processDirective(buildFileContents, Directive.EXTRACT_VERSION);
  }

  public void setupBuildFiles() throws IOException {
    String buildFileContents = BriefIO.fileToString(new File(blangHome, BUILD_FILE));
    // add blangSDK dependency
    buildFileContents = processDirective(buildFileContents, Directive.ADD_SDK_DEPENDENCY);
    // remove deployment info
    buildFileContents = processDirective(buildFileContents, Directive.TRIM);
    File generatedBuildFile = new File(compilationFolder, BUILD_FILE);
    BriefIO.write(generatedBuildFile, buildFileContents);
    // gradlew script
    File gradlewTo = new File(compilationFolder, "gradlew");
    if (!gradlewTo.exists())
      Files.copy(new File(blangHome, "gradlew").toPath(), gradlewTo.toPath());
    // and its dependencies
    Path wrapperDirTo = compilationFolder.toPath().resolve("gradle").resolve("wrapper");
    Files.createDirectories(wrapperDirTo);
    File wrapperJarTo = new File(wrapperDirTo.toFile(), "gradle-wrapper.jar");
    if (!wrapperJarTo.exists())
      Files.copy(blangHome.toPath().resolve("gradle").resolve("wrapper").resolve("gradle-wrapper.jar"), wrapperJarTo.toPath());
    File wrapperPropTo = new File(wrapperDirTo.toFile(), "gradle-wrapper.properties");
    if (!wrapperPropTo.exists())
      Files.copy(blangHome.toPath().resolve("gradle").resolve("wrapper").resolve("gradle-wrapper.properties"), wrapperPropTo.toPath());
    // need to give it an explicit name because gradle otherwise allocate the folder name which start with dot which gradle does not like
    File settings = new File(compilationFolder, "settings.gradle");
    if (!settings.exists())
      BriefIO.write(settings, "rootProject.name = \"" + projectName + "\"");
  
    Files.createDirectories(srcFolder);
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
        String depLine = "  compile group: 'com.github.UBC-Stat-ML', name: 'blangSDK', version: '" + compiler.blangSDKVersion() + "'";
        for (String dep : compiler.dependencies)
          depLine += "\n  compile '" + dep + "'";
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
      if (line.contains("blang-standalone-compiler-directive - do not edit : " + directive.toString()))
        return line;
    throw new RuntimeException();
  }
}

package blang.runtime.internals;

import java.io.File;

import com.google.common.io.Files;

import binc.Command;
import binc.Commands;

import static binc.Command.call;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.Inits;
import briefj.BriefIO;
import blang.System;

public class CreateBlangGradleProject implements Runnable
{
  @Arg(description = "Name of the project; should not be an existing directory or file name in current directory.") public String name;
  
  @Arg(description = "Github organization, used for example to generate travis files")
                       @DefaultValue("UBC-Stat-ML")
  public String githubOrganization = "UBC-Stat-ML";
  
  @Arg                  @DefaultValue("git")
  public Command git = Command.byName("git");
  
  public static String SETUP_ECLIPSE = "setup-eclipse.sh";
  public static String [] ROOT_FILES = {SETUP_ECLIPSE, ".gitignore", ".travis.yml"};
  public static String SETTINGS = ".settings";
  public static String GIT_IGNORE = ".gitignore";
  public static String [] SETTING_FILES = {"ca.ubc.stat.blang.BlangDsl.prefs", "org.eclipse.jdt.core.prefs", "org.eclipse.xtend.core.Xtend.prefs", "org.eclipse.xtext.java.Java.prefs"};
  public static String README = "README.md";
  
  @Override
  public void run() {
    File newProjectRoot = new File(".", name);
    if (newProjectRoot.exists()) throw new RuntimeException("File " + newProjectRoot + " already exists.");
    
    StandaloneCompiler compiler = new StandaloneCompiler(name, name);
    try { 
      System.out.println("Setting up build files");
      
      compiler.setupBuildFiles();
      for (String rootFile : ROOT_FILES)
        Files.copy(new File(compiler.blangHome, rootFile), new File(newProjectRoot, rootFile));

      File settingsFrom = new File(compiler.blangHome, SETTINGS);
      File settingsTo = new File(newProjectRoot, SETTINGS);
      settingsTo.mkdir();
      for (String settingFile : SETTING_FILES)
        Files.copy(new File(settingsFrom, settingFile), new File(settingsTo, settingFile));
      
      // Travis badge
      String readmeString = BriefIO.readLines(new File(compiler.blangHome, README)).first().get();
      readmeString = readmeString.replace("UBC-Stat-ML", githubOrganization).replace("blangSDK", name) + "\n" 
         + "-------";
      BriefIO.stringToFile(new File(newProjectRoot, README), readmeString); 
      
      // init repo, commit
      System.out.indentWithTiming("Setting up local git repository");
        Command gitInProject = git.ranIn(newProjectRoot).withStandardOutMirroring();
        call(gitInProject.appendArg("init").withStandardOutMirroring());
        call(gitInProject.appendArg("add").appendArg("-A").withStandardOutMirroring());
        call(gitInProject.appendArg("commit").appendArg("-m").appendArg("Add build files").withStandardOutMirroring());
      System.out.popIndent();
      
      // run setup eclipse
      System.out.indentWithTiming("Setting up eclipse configuration files");
        Command setupEclipse = Commands.bash.appendArg(new File(newProjectRoot, SETUP_ECLIPSE).getAbsolutePath());
        call(setupEclipse.ranIn(newProjectRoot).withStandardOutMirroring());
      System.out.popIndent();
      
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
  
  public static void main(String [] args) {
    Inits.parseAndRun(CreateBlangGradleProject.class, args);
  }
}

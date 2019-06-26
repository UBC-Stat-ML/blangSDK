package blang.runtime.internals;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class kevin {

  public static void main(String args[]) throws IOException {
    System.out.println(checkNoGradleArchitecture());
  }
  
  private static boolean checkNoGradleArchitecture() throws IOException {
    return Files.walk(Paths.get("/home/kevinchern/blang/JSSBlangCode"))
                  .filter(f -> !(f.startsWith(".blang-compilation") && f.endsWith("build.gradle")))
                  .anyMatch(f -> f.toString().endsWith("build.gradle"));
  }
  
}

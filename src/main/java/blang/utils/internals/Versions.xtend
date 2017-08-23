package blang.utils.internals

import java.util.Optional
import org.eclipse.jgit.lib.Repository
import java.util.Map
import java.util.LinkedHashMap
import java.util.List
import org.eclipse.jgit.lib.Ref
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.api.LogCommand
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.xtend.lib.annotations.Data

class Versions {
  
  @Data
  static class BadVersion extends RuntimeException {
    public val String message
  }
  
  def static String resolveVersion(
    Optional<String> optionalVersion, 
    Repository codeRepository
  ) {
    if (optionalVersion.present) {
      return optionalVersion.get
    } else {
      val Map<String,String> tag2commit = tag2commit(codeRepository)
      val String masterCommit = codeRepository.resolve("master").getName
      for (entry : tag2commit.entrySet) {
        if (entry.value == masterCommit) {
          return entry.key
        }
      }
      return masterCommit
    }
  }
  
  /**
   * Note: this should be called first in the main() otherwise some operations might be performed twice 
   * when an update occurs.
   */
  def static updateIfNeeded(
    Optional<String> optionalVersion, 
    Repository codeRepository,
    Runnable restart
  ) { 
    val Git git = new Git(codeRepository)
    val String currentCommit = codeRepository.resolve("HEAD").getName
    var Map<String,String> tag2commit = tag2commit(codeRepository)
    
    var String requestedCommit =  
      if (optionalVersion.present) {
        // could be null, if a pull is needed:
        tag2commit.get(optionalVersion.get) 
      } else {
        // by default, use master of local repo:
        codeRepository.resolve("master").getName
      }
    
    if (currentCommit == requestedCommit) { // requestedCommit needs to be on RHS to avoid npe
      return // nothing to do
    }
    
    if (optionalVersion.present) {
      // a "git pull" might be needed
      if (requestedCommit === null) {
        // try pulling
        git.fetch().setCheckFetchedObjects(true).call;
        tag2commit = tag2commit(codeRepository) // refresh tag2commit index after pull
        if (!tag2commit.keySet.contains(optionalVersion.get)) {
          throw new BadVersion("Version not found: " + optionalVersion.get + '\n' +
            "Versions available: " + tag2commit.keySet.join(", ")
          )
        }
      }
    }
    git.checkout().setName(requestedCommit).call
    restart.run
  }
  
  def static Map<String,String> tag2commit(Repository repository) {
    val Map<String,String> result = new LinkedHashMap
    val Git git = new Git(repository)
    val List<Ref> call = git.tagList().call();
    for (Ref ref : call) {
      // fetch all commits for this tag
      val LogCommand log = git.log();
      val Ref peeledRef = repository.peel(ref);
      if (peeledRef.getPeeledObjectId() != null) {
        log.add(peeledRef.getPeeledObjectId());
      } else {
        log.add(ref.getObjectId());
      }
      for (RevCommit rev : log.call()) {
        result.put(ref.getName, rev.getName)
      }
    }
    return result
  }
}
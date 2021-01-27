package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories
import blang.xdoc.components.Code.Language

class BlangCLI {
  
  public val static Document page = new Document("CLI") [
    
    category = Categories::tools 
    
    section("Installing Blang Command Line Interface (CLI)") [
        
      it += '''The prerequisites for the CLI installation process are:'''
      
      orderedList[
        
        it += '''A UNIX-compatible environment running «SYMB»bash«ENDSYMB». This includes, in particular, Mac OS
        X, where bash is the default terminal interpreter when launching Terminal.app.'''
        
        it += '''The «SYMB»git«ENDSYMB» command'''
        
        it += '''The Java Software Development Kit (SDK), version 8 or more recent (at the time of publication, 
        «SYMB»Open SDK«ENDSYMB» 8 and 11 are tested). The Java runtime environment is not sufficient, as 
        compilation of models requires compilation into the Java Virtual Machine. Type «SYMB»javac -version«ENDSYMB» to 
        test if the Java SDK is installed. If not, the Java SDK is freely available at 
        «LINK("https://openjdk.java.net/")»https://openjdk.java.net/«ENDLINK».'''
      ]
      
      it += '''The following installation process is most thoroughly tested on Mac OS X, which is the primary 
      supported platform at the moment, however users have reported installing it suc- cessfully on certain Linux 
      and Windows configurations and we plan to expand the set of officially supported platforms to both in the near future.
      To install the CLI tools, input the following commands in a bash terminal interpreter:
      '''
      
      code(Language::sh, '''
      git clone https://github.com/UBC-Stat-ML/blangSDK.git
      cd blangSDK
      source setup-cli.sh
      cd ..
      ''')
      
    ]
  ]
}
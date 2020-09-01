package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories
import blang.xdoc.components.Section

class BlangIDE {
  
  public val static Document page = new Document("Blang IDE") [
    
    category = Categories::tools
    
    section("Blang IDE setup instructions") [

      it += '''Download link for the Blang IDE «LINK(Home::downloadLink)»is available here«ENDLINK».'''
        
      section("System requirements") [
        it += '''
          The only requirement is that 
          «LINK("http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html")»Java 8 SDK«ENDLINK»
          should be installed on the system (version 9 not yet tested but is likely to work).'''
        it += '''        
          We only package the IDE for Mac at the moment but we can post instructions 
          on how to setup the IDE for other platforms (just email us). If you are a Linux or other 
          non-Mac Unix user, you can also use
          «LINK("https://github.com/UBC-Stat-ML/blangDoc/blob/master/using-eclipse-ide.md")»these provisional instructions«ENDLINK».
          
          The command line 
          tools are already shipped multi-platform.
        '''
      ]
      
      it += installBlang
        
      section("Creating a Blang project") [
        orderedList[
          it += '''Blang projects have some dependencies. Here's a robust way to get them:'''
          orderedList [
            it += '''From the terminal, «SYMB»cd«ENDSYMB» into «SYMB»[downloaded blang folder]/workspace/blangExample«ENDSYMB»'''
            it += '''«SYMB»./gradlew eclipse«ENDSYMB». This will download the dependencies.'''
          ]
          it += '''Now import in Blang IDE:'''
          orderedList[
            it += '''When asked which workspace to use, pick «SYMB»[downloaded blang folder]/workspace«ENDSYMB».'''
            it += '''Select menu «SYMB»File > Open Projects from File System...«ENDSYMB»'''
            it += '''Select «SYMB»[downloaded Blang folder]/workspace/blangExample«ENDSYMB»'''
          ]
          it += 
          '''
            The blang project is ready. In the left tool bar, the project is in the 
            file explorer. Right click on «SYMB»blangExample/src/main/java/demo/«ENDSYMB» and 
            select the contextual menu «SYMB»New > File«ENDSYMB». 
          '''
          it += '''Name the file «SYMB»MyModel.bl«ENDSYMB». The extension choice must always be «SYMB».bl«ENDSYMB»'''
        ]
      ]
      
      section("Using a model") [
        orderedList[
          it += '''Select menu «SYMB»Run > Run Configuration..«ENDSYMB»'''
          it += '''Click on «SYMB»Java Application«ENDSYMB»'''
          it += '''Click on the «SYMB»New Launch Configuration«ENDSYMB» on the top left.'''
          it += '''Fill the «SYMB»Main class«ENDSYMB» using the «SYMB»Search«ENDSYMB» button.'''
          it += '''In the tab «SYMB»Arguments«ENDSYMB» add any required arguments.'''
        ]
      ]
    ]
  ]
  
  public val static Section installBlang = new Section("Installing BlangIDE") [
      it += '''
        Really, "installing" amounts to unzipping and copying the contents. 
        The folder contains both the IDE, a template for your own projects, 
        and some command line tools. 
        
        The first time you try to launch BlangIDE, 
        depending on the version of Mac OS X and/or security settings, you may get 
        a message saying the "app is not registered with Apple by an identified developer". 
        To work around this, follow these instructions 
        («LINK("https://support.apple.com/kb/PH25088?locale=en_US")»from Apple«ENDLINK») 
        the first time you open the BlangIDE 
        (then Mac OS will remember your decision for subsequent launches):
      '''
      orderedList[
        it += '''
          In the Finder, locate BlangIDE (don't use Launchpad to do this). 
        '''
        it += '''
          Control-click the app icon, then choose Open from the shortcut menu.
        '''
      ] 
      it += '''
        If this does not work, an alternative is also described in the 
        «LINK("https://support.apple.com/kb/PH25088?locale=en_US")»same Apple help page«ENDLINK». 
      '''
  ]
  
}
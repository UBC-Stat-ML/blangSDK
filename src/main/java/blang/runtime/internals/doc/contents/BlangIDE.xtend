package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories

class BlangIDE {
  
  public val static Document page = new Document("Blang IDE") [
    
    category = Categories::tools
    
    section("Blang IDE setup instructions") [

      it += '''Download link for the Blang IDE «LINK(Home::downloadLink)»is available here«ENDLINK».'''
        
      section("System requirements") [
        it += '''
          The only requirement is that 
          «LINK("http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html")»Java 8 SDK«ENDLINK»
          should be installed on the system (version 9 not yet tested).'''
        it += '''        
          We only package the IDE for Mac at the moment but we can post instructions 
          on how to setup the IDE for other platforms (just email us). The command line 
          tools are already shipped multi-platform.'''
      ]
      
      section("Install") [
        it += '''
          Really, "installing" amounts to unzipping and copying the contents. 
          The folder contains both the IDE, a template for your own projects, 
          and some command line tools. '''
        it += '''
          The first time you open BlangIDE use «SYMB»command-O«ENDSYMB» to open 
          the app instead of double clicking (the app is not signed by an authority 
          at the moment, and «SYMB»command-O«ENDSYMB» by-passes the stringent default policy of not opening 
          such app. After the first time you can open it any way you want.'''
        ]
        
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
            it += '''Select «SYMB»[downloaded blang folder]/workspace/blangExample«ENDSYMB»'''
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
  
}
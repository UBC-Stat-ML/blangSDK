package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories

class BlangCLI {
  
  public val static Document page = new Document("CLI") [
    
    category = Categories::tools 
    
    section("Blang Command Line Interface (CLI) setup") [
      
      section("Prerequisites") [
        unorderedList[
          it += '''Java 8+ installed.'''
          it += '''Tested on a few UNIX architectures; in theory should run on windows but not tested yet.'''
        ]
      ]
      
      section("Instruction") [
        orderedList[
          it += '''
            Clone the «LINK("https://github.com/UBC-Stat-ML/blangSDK")»blangSDK repository«ENDLINK» 
            (also included in the main Blang download). 
          '''
          it += '''
            From the root of the SDK repo, run «SYMB»./setup-cli.sh«ENDSYMB» and follow the last step printed as output (setting up PATH).
          '''
        ]
      ]
      
      section("Usage") [
        orderedList[
          it += '''
            Create a directory for your project, say «SYMB»blangProject«ENDSYMB»
          '''
          it += '''
            Create a blang file, e.g. an empty model «SYMB»model MyModel { laws{} }«ENDSYMB», save it as «SYMB»blangProject/MyModel.bl«ENDSYMB»
            (Note: the extension «SYMB».bl«ENDSYMB» is required.)
          '''
          it += '''
            From «SYMB»blangProject«ENDSYMB», type «SYMB»blang --model MyModel«ENDSYMB»
          '''
          unorderedList[
            it += '''
              This will compile every «SYMB».bl«ENDSYMB» file in «SYMB»blangProject«ENDSYMB» (and its subdirectories, if any)
            '''
            it += '''
              After compilation, the model «SYMB»MyModel«ENDSYMB» will be ran (note that the file extension should be stripped here, in 
              parallel to standard Java conventions).
            '''
          ]
        ]
      ]
    ]
    
  ]
  
}
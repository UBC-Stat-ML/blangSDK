package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories

class BlangCLI {
  
  public val static Document page = new Document("CLI") [
    
    category = Categories::tools 
    
    section("Blang Command Line Interface (CLI) setup") [
      
      it += '''
        This page explains the simple possible method for using Blang from the command line. A more advanced 
        method is to use Blang within a Nextflow pipeline. This makes it easier to share and reproduce results, 
        and to systematically explore and combine several command line arguments. An example of how to do 
        this is available «LINK("https://github.com/UBC-Stat-ML/blang-mixture-tempering")»at this repository«ENDLINK».
      '''
      
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
            From the root of the SDK repo, run «SYMB»source setup-cli.sh«ENDSYMB».
          '''
        ]
      ]
      
      section("Usage") [
        orderedList[
          it += '''Type «SYMB»blang«ENDSYMB» and follow the instructions there, summarized below for convenience.'''
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
              After compilation, the model «SYMB»MyModel«ENDSYMB» will be ran.
            '''
          ]
        ]
      ]
    ]
    
  ]
  
}
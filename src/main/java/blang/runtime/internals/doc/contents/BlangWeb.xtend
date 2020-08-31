package blang.runtime.internals.doc.contents

import blang.xdoc.components.Document
import blang.runtime.internals.doc.Categories

class BlangWeb {
  
  public val static Document page = new Document("Blang via web") [
    
    category = Categories::tools
    
    section("Blang on the cloud via the browser") [
    
      it += '''Link to web app «LINK("https://silico.io")»is available here«ENDLINK».'''
      
      section("System requirements") [
        it += '''
          A modern browser (tested on Chrome and Firefox).'''
      ]
      
      section("Creating a Blang project") [
        orderedList[
          it += '''After signing up, create a «SYMB»Model«ENDSYMB».'''
          it += '''Using the gear icon, create a new file, name it to end in «SYMB».bl«ENDSYMB».'''
          it += '''With the gear icon again, set the file as «SYMB»entry«ENDSYMB»'''
        ]
      ]
      
      section("Using a Blang model") [
        orderedList[
          it += '''Click on «SYMB»Run«ENDSYMB».'''
          it += '''Command line options can be provided with a file name «SYMB»configuration.txt«ENDSYMB».'''
        ]
      ]
    
    ]
  
  ]
  
}
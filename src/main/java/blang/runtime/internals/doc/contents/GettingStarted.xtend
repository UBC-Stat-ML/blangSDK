package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.components.LinkTarget

class GettingStarted {
  
  public static val page = Document::create("Getting started") [
    it += '''All you need to get started is available in this download''' 
    downloadButton[
      label = "Get Blang"
      file = LinkTarget::url("downloads/blang-mac-latest.zip")
    ]
    // mac os for BlangIDE (give alternative instructions)
    // building stuff
    // warning that not from known developer
  ]
  
}
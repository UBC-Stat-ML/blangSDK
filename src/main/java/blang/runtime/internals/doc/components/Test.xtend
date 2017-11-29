package blang.runtime.internals.doc.components

class Test {
  def static void main(String [] args) {
    
    val Document doc = Document::create("name") [
      section("First section") [
        it += "asdfas"
        section("Subsection") [
          it += "asdfasd"
          orderedList [
            it += "first item"
            unorderedList [
              it += "sub item 1"
              it += "sub item 2"
            ]
            it += "second item"
          ]
        ]
      ]
    ]
    
//    val HTMLRender render = new HTMLRender
//    println(render.toString(doc))
    
  }
}
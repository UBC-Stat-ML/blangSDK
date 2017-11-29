package blang.runtime.internals.doc

import java.io.File
import java.util.Collection
import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.contents.Home
import blang.runtime.internals.doc.components.BootstrapHTMLRenderer
import blang.runtime.internals.doc.components.DocElement

class MakeHTMLDoc extends BootstrapHTMLRenderer {
  
  val static Collection<Document> documents = #[
    Home::page
  ]
  
  override protected String recurse(DocElement page) {
    // Add a fancy title to the home page
    return 
      {
        if (page === Home::page) 
          '''
          <div class="jumbotron jumbotron-fluid">
            <div class="container">
              <h1 class="display-3">Blang</h1>
              <p class="lead">Tools for Bayesian data science and probabilistic exploration</p>
            </div>
          </div>
          ''' 
        else ""
      }
      + super.recurse(page)
  }
  
  new() {
    super("Blang Doc", documents)
  }
  
  def static void main(String [] args) {
    val mkDoc = new MakeHTMLDoc
    mkDoc.renderInto(new File("."))
  }
}
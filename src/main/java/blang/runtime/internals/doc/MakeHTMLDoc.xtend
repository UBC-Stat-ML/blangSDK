package blang.runtime.internals.doc

import java.io.File
import java.util.Collection
import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.contents.Home
import blang.runtime.internals.doc.components.BootstrapHTMLRenderer
import blang.runtime.internals.doc.components.DocElement
import blang.runtime.internals.doc.contents.Reference
import blang.runtime.internals.doc.contents.GettingStarted
import java.util.List
import java.util.ArrayList
import blang.runtime.internals.doc.contents.BlangIDE
import blang.runtime.internals.doc.contents.BlangWeb

class MakeHTMLDoc extends BootstrapHTMLRenderer {
  
  val static Collection<Document> documents = #[
    Home::page,
    GettingStarted::page,
    BlangIDE::page,
    BlangWeb::page,
    Reference::page
  ]
  
  override protected List<String> recurse(DocElement page) {
    val List<String> result = new ArrayList
    if (page === Home::page) {
      result.add(
        '''
          <div class="jumbotron-bg jumbotron jumbotron-fluid">
            <div class="container">
              <h1 class="display-3">Blang</h1>
              <p class="lead">Tools for Bayesian data science and probabilistic exploration</p>
            </div>
          </div>
          <p class="lead">
            Blang is a language and software development kit for doing Bayesian analysis. 
            Our design philosophy is centered around the day-to-day requirements of real world 
            data analysis. We have also used Blang as a teaching tool, both for basic probability 
            concepts and more advanced Bayesian modelling. Here is the one minute tour:
          </p>
        '''
      ) 
    }
    if (page === GettingStarted::page) {
      result.add(
        '''
          <div class="jumbotron jumbotron-fluid">
            <div class="container">
              <p class="lead">All you need to get started is available in this zip file:</p>
              
              <div class="text-center"> 
                <br/>
                <a href="«Home::downloadLink»" role="button" class="btn-success btn-lg">
                  Download zip
                </a>
                &nbsp;
                <a href="https://silico.io" role="button" class="btn-success btn-lg">
                  Blang in the browser
                </a>
                <br/>
              </div> 
            </div>
          </div>
        '''
      )
    }
    result.addAll(super.recurse(page))
    return result
  }
  
  new() {
    super("Blang Doc", documents)
  }
  
  def static void main(String [] args) {
    val mkDoc = new MakeHTMLDoc
    mkDoc.renderInto(new File("."))
  }
}
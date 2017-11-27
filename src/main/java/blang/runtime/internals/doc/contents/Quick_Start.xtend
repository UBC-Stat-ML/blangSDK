package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Page

import static blang.runtime.internals.doc.components.Components.*

class Quick_Start extends Page {
   
  override contents() {
    section [
      in += '''
      <div class="jumbotron jumbotron-fluid">
        <div class="container">
          <h1 class="display-3">Blang</h1>
          <p class="lead">Tools for Bayesian data science and probabilistic exploration</p>
        </div>
      </div>
      '''
      subsection [
        in += '''
          Blang is a language and software development kit for doing Bayesian analysis. 
          Our design philosophy is centered around the day-to-day requirements of real world 
          data analysis. We have also used Blang as a teaching tool, both for basic probability 
          concepts and more advanced Bayesian modelling. 
        '''
      ]
      subsection [
        name = "Quick start"
        in += '''
          TODO: some quick example. Something involving normalization constants?
        '''
      ]
    ]
  }
  
}
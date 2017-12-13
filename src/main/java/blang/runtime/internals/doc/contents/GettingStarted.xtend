package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document

import static extension blang.runtime.internals.doc.DocElementExtensions.code
import blang.validation.internals.fixtures.Doomsday

class GettingStarted {
  
  public static val page = Document::create("Getting started") [
    
    section("Blang: a fifteen minutes tutorial") [
      
      it += '''While the download proceeds, here is short tutorial on Blang. '''

      section("Models") [
        it += '''A Blang «SYMB»model«ENDSYMB» specifies a joint probability distribution over a collection of random variables.'''
        it += '''
          Here is an example, based on a very simple model for the famous 
          «LINK("https://en.wikipedia.org/wiki/Doomsday_argument")»Doomsday argument«ENDLINK»:'''
        code(Doomsday) [ replaceAll("package [a-z.]*", "package demo") ]
        it += '''
          «SYMB»Doomsday«ENDSYMB» is a just a name we give to this model. As a convention, we encourage users to capitalize model names 
          (Blang is case-sensitive). '''
      ]
      
      section("Random variables") [
        it += '''
          Variables need to specify their type, e.g.: «SYMB»random RealVar z«ENDSYMB» is of type «SYMB»RealVar«ENDSYMB» and
           we give it the name «SYMB»z«ENDSYMB». Here «SYMB»random«ENDSYMB» is a Blang keyword.'''
        it += '''As a convention, types are capitalized, variable names are not.''' 
      ]
      
      section("Laws") [
        it += '''
          The section «SYMB»laws { ... }«ENDSYMB» defines distribution and conditional distributions on the random variables. 
          The syntax is the same as the notation used in probability theory. For example, «SYMB»y | z ~ ContinuousUniform(0.0, z)«ENDSYMB» 
          means that the conditional distribution of «SYMB»y«ENDSYMB» given «SYMB»z«ENDSYMB» is uniformly distributed between zero and «SYMB»z«ENDSYMB».
          '''
      ]
      
      section("Performing inference") [ // TODO: 
        it += '''
          Each blang model is turned into a program supporting various inference methods. 
          To demonstrate that, let's run the above example. '''
        orderedList[
          it += '''
            Setup one of these two methods: 
            «LINK(BlangWeb::page)»running blang with the Web App«ENDLINK», or 
            «LINK(BlangIDE::page)»with the Blang IDE«ENDLINK».''' 
          it += '''
            Once you follow the above steps, you will get a message about missing arguments. 
            These arguments essentially control the data the model should condition on, as well 
            as the algorithm used to approximate the conditional expectation (the 'inference engine').
            The arguments are automatically discovered with the minimal helps of some annotations. 
            We will cover that later. For now, let's provide the minimal set:'''
        ]
        
        
      ]
      
    ]
    
    section("More pointers") [
      it += "TODO"
    ]

  ]
  
}
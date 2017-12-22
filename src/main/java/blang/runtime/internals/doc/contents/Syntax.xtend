package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import blang.runtime.internals.doc.components.Code.Language

class Syntax {
  
  public val static Document page = new Document("Syntax reference") [
    category = Categories::reference
    
    section("Comments") [
      it += '''
        Single line comments use the syntax «SYMB»// some comment spanning the rest of the line«ENDSYMB».
        
        Multi-line comments use «SYMB»/* many lines can go here */«ENDSYMB».
        
        In the following, we use comments to give contextual explanation on syntax examples.
      '''
    ]
    
    section("Model") [
      it += '''Models follow the following syntax:'''
      code(Language.blang, '''
        package my.namespace // optional
        
        // import statements
        
        model NameOfModel {
          
          // variables declarations
          
          laws {
            // laws declaration 
          }
          
          generate(nameOfRandomObject) { // optional
            // generate block 
          }
        }
      ''')
      
      section("Package and import") [
        it += '''
          Packages in Blang work as in Java. Their syntax is similar too except that the semicolumn can be skipped in 
          Blang.
          
          Similarly, «SYMB»import«ENDSYMB» statements also support the Java counterparts, for example: 
        '''  
        code(Language.blang, '''
          import org.apache.spark.sql.Dataset
          import static org.apache.spark.sql.functions.col
        ''')
        it += '''
          «SYMB»import static«ENDSYMB» is used to import a function (the function called «SYMB»col«ENDSYMB» in
          the above example), while standard imports are for types. The name "static" comes from Java where "static method" means 
          a "regular" function, i.e. a procedure that exists outside of the context of an object. 
          
          Blang additionally support import directives of the form'''
       code(Language.blang, '''import static extension my.namespace.myfunction''')
       it += '''
          allowing 
          to write «SYMB»arg1.myfunction(arg2, ...)«ENDSYMB» instead of «SYMB»myfunction(arg1, arg2, ...)«ENDSYMB».
          
          Blang automatically imports:  
       '''
       unorderedList[ // TODO extract those
         it += '''
          all the types in the following packages: 
            «SYMB»blang.core«ENDSYMB», 
            «SYMB»blang.distributions«ENDSYMB»,
            «SYMB»blang.io«ENDSYMB», 
            «SYMB»blang.types«ENDSYMB», 
            «SYMB»blang.mcmc«ENDSYMB», 
            «SYMB»java.util«ENDSYMB», 
            «SYMB»xlinear«ENDSYMB»;
         '''
         it += '''
          all the static function in the following files: 
            «SYMB»xlinear.MatrixOperations«ENDSYMB», 
            «SYMB»bayonet.math.SpecialFunctions«ENDSYMB», 
            «SYMB»org.apache.commons.math3.util.CombinatoricsUtils«ENDSYMB», 
            «SYMB»blang.types.StaticUtils«ENDSYMB»; 
         '''
         it += '''
          as static extensions all the static function in the following files:
            «SYMB»xlinear.MatrixExtensions«ENDSYMB», 
            «SYMB»blang.types.ExtensionUtils«ENDSYMB».  
         '''
       ]
      ]
      
      section("Variables declarations") [
        it += '''
          Variables are declared using the following syntax:
        '''
        code(Language.blang, '''
          random Type1 name1
          random Type2 name2 ?: { ... } // optional initialization block
          random Type3 name3 ?: someStaticallyImportedFunction(name2) // another optional init
          param Type4 name4
          param Type5 name5 ?: { .. } // one more optional init block 
        ''')
        it += '''
          Each variable is declared as either «SYMB»random«ENDSYMB »or «SYMB»param«ENDSYMB» (parameter). 
          This controls how the model can be invoked by other models. 
          Parameters can become random when the model is used in the context of a larger model.
          
          In the above example, «SYMB»Type1«ENDSYMB», «SYMB»Type2«ENDSYMB», ... can syntactically 
          be of any type. However at runtime some requirement 
          «LINK(GettingStarted::page)»must be met by these types«ENDLINK». 
          
          When there are no 
        '''
      ]
      
    ]
    
  ]
  
}
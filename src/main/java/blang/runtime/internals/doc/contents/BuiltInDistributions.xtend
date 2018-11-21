package blang.runtime.internals.doc.contents

import blang.runtime.internals.doc.components.Document
import blang.runtime.internals.doc.Categories
import blang.distributions.Bernoulli

import static extension blang.runtime.internals.doc.DocElementExtensions.documentClass
import blang.distributions.Beta
import blang.distributions.Binomial
import blang.distributions.Categorical
import blang.distributions.ContinuousUniform
import blang.distributions.Dirichlet
import blang.distributions.DiscreteUniform
import blang.distributions.Exponential
import blang.distributions.Gamma
import blang.distributions.MultivariateNormal
import blang.distributions.NegativeBinomial
import blang.distributions.Normal
import blang.distributions.NormalField
import blang.distributions.Poisson
import blang.distributions.SimplexUniform
import blang.distributions.SymmetricDirichlet
import blang.distributions.LogPotential
import blang.distributions.StudentT
import blang.distributions.HalfStudentT
import blang.distributions.ChiSquared
import blang.distributions.YuleSimon
import blang.distributions.Pareto

class BuiltInDistributions {
  
  public val static Document page = new Document("Distributions") [
    
    category = Categories::reference
    
    section("Discrete") [
      documentClass(Bernoulli)
      documentClass(Binomial)
      documentClass(Categorical)
      documentClass(DiscreteUniform)
      documentClass(Poisson)
      documentClass(NegativeBinomial)
      documentClass(YuleSimon)
    ]
    
    section("Continuous") [
      documentClass(ContinuousUniform)
      documentClass(Exponential)
      documentClass(Normal)
      documentClass(Beta)
      documentClass(Gamma)
      documentClass(StudentT)
      documentClass(HalfStudentT)
      documentClass(ChiSquared)
      documentClass(Pareto)
    ]
    
    section("Multivariate") [
      documentClass(MultivariateNormal)
      documentClass(NormalField)
      documentClass(Dirichlet)
      documentClass(SymmetricDirichlet)
      documentClass(SimplexUniform)
    ]
    
    section("Misc") [
      documentClass(LogPotential)
    ]

  ]
  
}
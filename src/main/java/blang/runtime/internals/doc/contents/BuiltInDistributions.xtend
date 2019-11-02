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
import blang.distributions.Geometric
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
import blang.distributions.Laplace
import blang.distributions.Logistic
import blang.distributions.LogLogistic
import blang.distributions.F
import blang.distributions.Weibull
import blang.distributions.Gumbel
import blang.distributions.Gompertz
import blang.distributions.HyperGeometric
import blang.distributions.BetaBinomial
import blang.distributions.BetaNegativeBinomial
import blang.distributions.GammaMeanParam
import blang.distributions.LogUniform
import blang.distributions.NegativeBinomialMeanParam

class BuiltInDistributions {
  
  public val static Document page = new Document("Distributions") [
    
    category = Categories::reference
    
    section("Discrete") [
      documentClass(Bernoulli)
      documentClass(BetaBinomial)
      documentClass(BetaNegativeBinomial)
      documentClass(Binomial)
      documentClass(Categorical)
      documentClass(DiscreteUniform)
      documentClass(Geometric)
      documentClass(HyperGeometric)
      documentClass(NegativeBinomial)
      // documentClass(NegativeBinomialMeanParam) // Commented as not documented at the moment
      documentClass(Poisson)
      documentClass(YuleSimon)
    ]
    
    section("Continuous") [
      documentClass(Beta)
      documentClass(ChiSquared)
      documentClass(ContinuousUniform)
      documentClass(Exponential)
      documentClass(F)
      documentClass(Gamma)
      // documentClass(GammaMeanParam) // Commented as not documented at the moment
      documentClass(Gompertz)
      documentClass(Gumbel)
      documentClass(HalfStudentT)
      documentClass(Laplace)
      documentClass(Logistic)
      documentClass(LogLogistic)
      documentClass(LogUniform)
      documentClass(Normal)
      documentClass(StudentT)
      documentClass(Weibull)
    ]
    
    section("Multivariate") [
      documentClass(Dirichlet)
      documentClass(MultivariateNormal)
      documentClass(NormalField)
      documentClass(SimplexUniform)
      documentClass(SymmetricDirichlet)
    ]
    
    section("Misc") [
      documentClass(LogPotential)
    ]

  ]
  
}
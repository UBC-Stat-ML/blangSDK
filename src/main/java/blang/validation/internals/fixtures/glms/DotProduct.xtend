package blang.validation.internals.fixtures.glms

import blang.core.RealVar
import blang.types.Plated
import java.util.ArrayList
import java.util.List
import blang.types.Plate
import blang.types.Index

class DotProduct {
  
  val List<RealVar> parameters = new ArrayList
  val List<Double> covariates = new ArrayList
  
  def static <T> DotProduct of(Plate<T> features, Plated<? extends RealVar> parameters, Plated<? extends Number> covariates) {
    val result = new DotProduct 
    for (Index<T> feature : features.indices) {
      val covariate = covariates.get(feature).doubleValue
      if (covariate != 0.0 && covariate != -0.0) {
        result.covariates.add(covariate)
        result.parameters.add(parameters.get(feature))
      }
    }
    return result
  }
  
  def double compute() {
    var result = 0.0
    for (var int i = 0; i < parameters.size; i++)
      result += parameters.get(i).doubleValue * covariates.get(i)
    return result
  }
}
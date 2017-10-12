package blang.validation.internals.fixtures;

import java.util.function.Function;

import blang.core.UnivariateModel;
import xlinear.Matrix;

public class VectorHash implements Function<UnivariateModel<? extends Matrix>, Double>  
{

  @Override
  public Double apply(UnivariateModel<? extends Matrix> t) 
  {
    double sum = 0.0;
    for (int i = 0; i < t.realization().nEntries(); i++)
      sum += (i+1) * Math.pow(t.realization().get(i), 2.0);
    return sum; 
  }

}

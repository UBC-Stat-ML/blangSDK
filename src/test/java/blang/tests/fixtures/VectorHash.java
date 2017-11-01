package blang.tests.fixtures;

import java.util.function.Function;

import blang.core.UnivariateModel;
import xlinear.Matrix;

public class VectorHash implements Function<UnivariateModel<? extends Matrix>, Double>  
{

  @Override
  public Double apply(UnivariateModel<? extends Matrix> t) 
  {
    return hash(t.realization());
  }
  
  public static double hash(Matrix m) 
  {
    double sum = 0.0;
    for (int i = 0; i < m.nEntries(); i++)
      sum += (i+1) * Math.pow(m.get(i), 2.0);
    return sum; 
  }

}

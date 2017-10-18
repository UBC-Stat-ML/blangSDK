package blang.validation.internals.fixtures;

import java.util.List;
import java.util.function.Function;

import blang.core.IntVar;
import blang.core.UnivariateModel;

public class ListHash implements Function<UnivariateModel<? extends List<IntVar>>, Double>  
{

  @Override
  public Double apply(UnivariateModel<? extends List<IntVar>> t) 
  {
    double sum = 0.0;
    for (int i = 0; i < t.realization().size(); i++)
      sum += (i+1) * Math.pow(t.realization().get(i).intValue(), 2.0);
    return sum; 
  }

}

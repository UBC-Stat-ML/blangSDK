package blang.tests.fixtures;

import java.util.List;
import java.util.function.Function;

import blang.core.IntVar;
import blang.core.UnivariateModel;

public class ListHash implements Function<UnivariateModel<? extends List<IntVar>>, Double>  
{

  @Override
  public Double apply(UnivariateModel<? extends List<IntVar>> t) 
  {
    return hash(t.realization());
  }
  
  public static double hash(List<IntVar> list)
  {
    double sum = 0.0;
    for (int i = 0; i < list.size(); i++)
      sum += (i+1) * Math.pow(list.get(i).intValue(), 2.0);
    return sum;
  }

}

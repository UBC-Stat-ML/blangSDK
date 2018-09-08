package blang.validation.internals.fixtures;

import java.util.List;
import java.util.function.Function;

import blang.core.IntVar;
import blang.core.UnivariateModel;

public class IntListFirstComponentOfRealizationSquared implements Function<UnivariateModel<? extends List<IntVar>>, Double>  
{

  @Override
  public Double apply(UnivariateModel<? extends List<IntVar>> t) 
  {
    return (double) t.realization().get(0).intValue();
  }

}

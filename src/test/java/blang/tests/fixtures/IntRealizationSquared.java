package blang.tests.fixtures;

import java.util.function.Function;

import blang.core.IntVar;
import blang.core.UnivariateModel;

public class IntRealizationSquared implements Function<UnivariateModel<IntVar>, Double>
{

  @Override
  public Double apply(UnivariateModel<IntVar> t) 
  {
    return Math.pow(t.realization().intValue(), 2.0);
  }

}

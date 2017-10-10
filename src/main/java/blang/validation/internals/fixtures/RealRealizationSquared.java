package blang.validation.internals.fixtures;

import java.util.function.Function;

import blang.core.RealVar;
import blang.core.UnivariateModel;

public class RealRealizationSquared implements Function<UnivariateModel<RealVar>, Double>
{

  @Override
  public Double apply(UnivariateModel<RealVar> t) 
  {
    return Math.pow(t.realization().doubleValue(), 2.0);
  }

}

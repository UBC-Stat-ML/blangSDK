package blang.runtime.internals.objectgraph;

import java.util.ArrayList;
import java.util.List;

import blang.core.LogScaleFactor;
import blang.core.SupportFactor;

public class SafeFactor implements LogScaleFactor
{
  // placed in package objectgraph so that GraphAnalysis can modify this field
  @SkipDependency(isMutable = false) // can skip since by construction the reach has to be subset of enclosed
  final List<SupportFactor> preconditions = new ArrayList<>();
  
  public final LogScaleFactor enclosed;
  
  public SafeFactor(LogScaleFactor enclosed) 
  {
    super();
    this.enclosed = enclosed;
  }

  @Override
  public double logDensity()
  {
    for (SupportFactor support : preconditions)
      if (!support.isInSupport())
        return Double.NEGATIVE_INFINITY;
    return enclosed.logDensity();
  }
}

package blang.engines.internals;

import blang.engines.internals.factories.Exact;
import blang.engines.internals.factories.Forward;
import blang.engines.internals.factories.None;
import blang.engines.internals.factories.PT;
import blang.engines.internals.factories.SCM;
import blang.inits.Implementations;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

@Implementations({SCM.class, PT.class, Forward.class, Exact.class, None.class})
public interface PosteriorInferenceEngine 
{
  public void setSampledModel(SampledModel model);
  public void performInference();
  public void check(GraphAnalysis analysis);
}

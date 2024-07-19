package blang.engines.internals.factories

import blang.runtime.SampledModel

class IAIS extends ISCM {
  override void setSampledModel(SampledModel model) {
    resamplingESSThreshold = 0.0
    super.setSampledModel(model)
  }
}
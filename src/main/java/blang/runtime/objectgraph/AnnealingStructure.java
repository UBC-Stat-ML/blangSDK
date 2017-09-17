package blang.runtime.objectgraph;

import java.util.ArrayList;
import java.util.List;

import blang.core.AnnealedFactor;
import blang.core.Factor;
import blang.core.LogScaleFactor;
import blang.mcmc.ExponentiatedFactor;
import blang.types.RealScalar;

public class AnnealingStructure 
{
  public final RealScalar annealingParameter;
  
  // Those that are not annealed (e.g. priors)
  public final List<LogScaleFactor> fixedLogScaleFactors = new ArrayList<>();
  public final List<Factor> otherFixedFactors = new ArrayList<>();
  
  // Those that are annealed
  public final List<ExponentiatedFactor> exponentiatedFactors = new ArrayList<>();
  public final List<AnnealedFactor> otherAnnealedFactors = new ArrayList<>();
  
  public AnnealingStructure(RealScalar annealingParameter) 
  {
    this.annealingParameter = annealingParameter;
  }
}

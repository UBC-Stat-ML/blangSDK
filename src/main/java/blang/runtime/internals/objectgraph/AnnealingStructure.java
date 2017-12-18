package blang.runtime.internals.objectgraph;

import java.util.ArrayList;
import java.util.List;

import blang.core.AnnealedFactor;
import blang.core.Factor;
import blang.core.LogScaleFactor;
import blang.mcmc.internals.ExponentiatedFactor;
import blang.types.internals.RealScalar;

public class AnnealingStructure 
{
  public final RealScalar annealingParameter;
  
  // Those that are not annealed (e.g. priors, Constrained, etc)
  public final List<LogScaleFactor> fixedLogScaleFactors = new ArrayList<>();
  public final List<Factor> otherFactors = new ArrayList<>();
  
  // Those that are annealed
  public final List<ExponentiatedFactor> exponentiatedFactors = new ArrayList<>();
  public final List<AnnealedFactor> otherAnnealedFactors = new ArrayList<>(); // custom (not yet used)
  
  public AnnealingStructure(RealScalar annealingParameter) 
  {
    this.annealingParameter = annealingParameter;
  }
}

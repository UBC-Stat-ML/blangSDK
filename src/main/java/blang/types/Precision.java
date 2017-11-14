package blang.types;

import java.util.LinkedHashSet;
import java.util.Set;

import blang.core.RealVar;
import briefj.collections.UnorderedPair;

// TODO: move to separate package, generalize to GLMs, call package glm

// Examples: Time series, Spatial; abstract kernel based version
public interface Precision  // Dev note: avoiding generics here as they cause bunch of problems when used in blang models (believe me, tried many things)
{
  Plate getPlate();
  Set<UnorderedPair> support();
  double logDet();
  double get(UnorderedPair pair);
  
  
  public static class Diagonal implements Precision
  {
    final RealVar diagonalPrecisionValue;
    final Plate<?> plate;
    final int dim;
    
    public Diagonal(RealVar diagonalPrecisionValue, Plate<?> plate) 
    {
      this.plate = plate;
      this.dim = plate.indices().size();
      this.diagonalPrecisionValue = diagonalPrecisionValue;
    }

    @Override
    public Set<UnorderedPair> support() 
    {
      Set result = new LinkedHashSet<>();
      for (Index index : plate.indices())
        result.add(UnorderedPair.of(index.key, index.key));
      return result;
    }

    @Override
    public double logDet() 
    {
      return dim * Math.log(diagonalPrecisionValue.doubleValue());
    }

    @Override
    public double get(UnorderedPair entry) 
    {
      return diagonalPrecisionValue.doubleValue();
    }

    @Override
    public Plate getPlate() {
      return plate;
    }
    
  }
}

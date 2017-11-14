package blang.types;

import java.util.LinkedHashSet;
import java.util.Set;

import blang.core.RealVar;
import briefj.collections.UnorderedPair;

// TODO: move to separate package, generalize to GLMs, call package glm

// Examples: Time series, Spatial; abstract kernel based version
public interface Precision  // TODO: get rid of that generic type?
{
  <K> Plate<K> getPlate();
  <K> Set<UnorderedPair<K, K>> support();
  double logDet();
  <K> double get(UnorderedPair<K, K> entry);
  
  
  public static class Diagonal implements Precision
  {
    final RealVar diagonalPrecisionValue;
    final Plate<?> plate;
    final int dim;
    
    public Diagonal(RealVar diagonalPrecisionValue, Plate plate) 
    {
      this.plate = plate;
      this.dim = plate.indices().size();
      this.diagonalPrecisionValue = diagonalPrecisionValue;
    }

    @Override
    public <K> Set<UnorderedPair<K, K>> support() 
    {
      Set result = new LinkedHashSet<>();
      for (Index<?> index : plate.indices())
        result.add(UnorderedPair.of(index.key, index.key));
      return result;
    }

    @Override
    public double logDet() 
    {
      return dim * Math.log(diagonalPrecisionValue.doubleValue());
    }

    @Override
    public <K> double get(UnorderedPair<K, K> entry) 
    {
      return diagonalPrecisionValue.doubleValue();
    }

    @Override
    public Plate getPlate() {
      return plate;
    }
    
  }
}

package blang.types;

import xlinear.Matrix;

public interface Simplex extends Matrix 
{
  @Override
  default public void set(int i, int j, double value) {
    throw new RuntimeException("Use setPair instead");
  }
}

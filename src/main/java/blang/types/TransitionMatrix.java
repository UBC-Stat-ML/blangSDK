package blang.types;

import xlinear.Matrix;

public interface TransitionMatrix extends Matrix
{
  public Simplex row(int i);
  
  @Override
  default public void set(int i, int j, double value) {
    throw new RuntimeException("Get  row(..).setPair instead");
  }
}

package blang.runtime.internals.objectgraph;

import org.eclipse.xtext.xbase.lib.Pair;
 
import blang.types.RealMatrixComponent;
import xlinear.Matrix;
import xlinear.internals.Slice;

public class MatrixConstituentNode extends ConstituentNode<Pair<Integer,Integer>>
{
  public MatrixConstituentNode(Matrix matrix, int row, int col) 
  {
    super(findRoot(matrix), getRootKey(matrix, row, col));
  }
  
  private static Pair<Integer,Integer> getRootKey(Matrix matrix, int row, int col)
  {
    int rowOffSet = 0;
    int colOffSet = 0;
    if (matrix instanceof Slice)
    {
      rowOffSet = ((Slice) matrix).row0Incl;
      colOffSet = ((Slice) matrix).col0Incl;
    }
    return Pair.of(rowOffSet + row, colOffSet + col);
  }
  
  private static Matrix findRoot(Matrix matrix) 
  {
    if (matrix instanceof Slice)
      return ((Slice) matrix).rootMatrix;
    else
      return matrix;
  }

  @Override
  public Object resolve()
  {
    return new RealMatrixComponent(key.getKey(), key.getValue(), (Matrix) container);
  }
  
  @Override
  public String toStringSummary()
  {
    return "" + key;
  }

  @Override
  public boolean isMutable()
  {
    return true;
  }
}
package blang.runtime.internals.objectgraph;

import org.eclipse.xtext.xbase.lib.Pair;

import blang.core.WritableRealVar;
import blang.mcmc.RealNaiveMHSampler;
import blang.mcmc.Samplers;
import xlinear.Matrix;
import xlinear.internals.Slice;

@Samplers({RealNaiveMHSampler.class}) 
public class MatrixConstituentNode extends ConstituentNode<Pair<Integer,Integer>> implements WritableRealVar
{
  // These should stay private and without getter/setter 
  // Making them accessible is probably symptom of a bug, see e.g. commit b8c2f2f6df416c2d64527c373356965b1daec583
  private final Matrix container;
  private final int row;
  private final int col;
  
  public MatrixConstituentNode(Matrix matrix, int row, int col) 
  {
    super(findRoot(matrix), getRootKey(matrix, row, col));
    this.container = findRoot(matrix);
    this.row = row;
    this.col = col;
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
    return null;
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

  @Override
  public double doubleValue() 
  {
    return container.get(row, col);
  }

  @Override
  public void set(double value) 
  {
    container.set(row, col, value);
  }
}
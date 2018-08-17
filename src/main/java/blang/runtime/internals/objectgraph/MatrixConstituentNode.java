package blang.runtime.internals.objectgraph;

import org.eclipse.xtext.xbase.lib.Pair;

import blang.core.WritableRealVar;
import blang.mcmc.RealSliceSampler;
import blang.mcmc.Samplers;
import blang.types.internals.Delegator;
import xlinear.Matrix;
import xlinear.internals.Slice;

@Samplers({RealSliceSampler.class}) 
public class MatrixConstituentNode extends ConstituentNode<Pair<Integer,Integer>> implements WritableRealVar
{
  // These should stay private and without getter/setter 
  // Making them accessible is probably symptom of a bug, see e.g. commit b8c2f2f6df416c2d64527c373356965b1daec583
  private final Matrix container;
  private final boolean mutable;
  
  public MatrixConstituentNode(Matrix matrix, int row, int col) 
  {
    super(findRoot(matrix), getRootKey(matrix, row, col));
    this.mutable = isMutable(matrix);
    this.container = findRoot(matrix);
  }
  
  public static Matrix findDelegate(Matrix m) 
  {
    if (m instanceof Delegator<?>) 
      return findDelegate((Matrix) ((Delegator<?>) m).getDelegate());
    else
      return m;
  }
  
  public static boolean isMutable(Matrix m) 
  {
    if (m instanceof Slice)
      return !((Slice) m).isReadOnly();
    else if (m instanceof Delegator<?>) 
      return isMutable((Matrix) ((Delegator<?>) m).getDelegate());
    else 
      return true;
  }
  
  private static Pair<Integer,Integer> getRootKey(Matrix matrix, int row, int col)
  {
    int rowOffSet = 0;
    int colOffSet = 0;
    matrix = findDelegate(matrix); // needed when called from ExtensionUtils
    if (matrix instanceof Slice)
    {
      rowOffSet = ((Slice) matrix).row0Incl;
      colOffSet = ((Slice) matrix).col0Incl;
    }
    return Pair.of(rowOffSet + row, colOffSet + col);
  }
  
  private static Matrix findRoot(Matrix matrix) 
  {
    matrix = findDelegate(matrix); // needed when called from ExtensionUtils
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
    return mutable; 
  }

  @Override
  public double doubleValue() 
  {
    return container.get(key.getKey(), key.getValue());
  }

  @Override
  public void set(double value) 
  {
    container.set(key.getKey(), key.getValue(), value);
  }
}
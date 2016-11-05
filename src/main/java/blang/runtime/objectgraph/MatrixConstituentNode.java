package blang.runtime.objectgraph;

import org.eclipse.xtext.xbase.lib.Pair;
 
import blang.types.RealMatrixComponent;
import xlinear.Matrix;
import xlinear.internals.Slice;

public class MatrixConstituentNode extends ConstituentNode<Pair<Integer,Integer>>
{
  public MatrixConstituentNode(Matrix container, Pair<Integer,Integer> key)
  {
    super(container, key);
    if (container instanceof Slice) {
      throw new RuntimeException();
    }
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
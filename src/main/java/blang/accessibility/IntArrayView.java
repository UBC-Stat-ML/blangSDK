package blang.accessibility;

import com.google.common.collect.ImmutableList;



public final class IntArrayView extends ArrayView
{
  @ViewedArray
  private final int[] viewedArray;
  
  public IntArrayView(ImmutableList<Integer> viewedIndices, int[] viewedArray)
  {
    super(viewedIndices);
    this.viewedArray = viewedArray;
  }

  public int get(int indexIndex)
  {
    return viewedArray[viewedIndices.get(indexIndex)];
  }
  
  public void set(int indexIndex, int object)
  {
    viewedArray[viewedIndices.get(indexIndex)] = object;
  }
}
package blang.accessibility;

import com.google.common.collect.ImmutableList;



public final class ObjectArrayView<T> extends ArrayView
{
  @ViewedArray
  private final T[] viewedArray;
  
  public ObjectArrayView(ImmutableList<Integer> viewedIndices, T[] viewedArray)
  {
    super(viewedIndices);
    this.viewedArray = viewedArray;
  }

  public T get(int indexIndex)
  {
    return viewedArray[viewedIndices.get(indexIndex)];
  }
  
  public void set(int indexIndex, T object)
  {
    viewedArray[viewedIndices.get(indexIndex)] = object;
  }
}
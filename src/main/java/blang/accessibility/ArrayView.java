package blang.accessibility;

import com.google.common.collect.ImmutableList;



abstract class ArrayView
{
  public final ImmutableList<Integer> viewedIndices;

  public ArrayView(ImmutableList<Integer> viewedIndices)
  {
    this.viewedIndices = viewedIndices;
  }
}
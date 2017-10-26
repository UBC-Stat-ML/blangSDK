package blang.types;

import java.util.Set;

import briefj.collections.UnorderedPair;

public interface Precision 
{
  Set<UnorderedPair<Integer, Integer>> support();
  double logDet();
  double get(UnorderedPair<Integer, Integer> entry);
  int dim();
}

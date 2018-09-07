package blang.validation.internals.fixtures

import briefj.collections.UnorderedPair
import java.util.List
import java.util.ArrayList

class Functions {
  def static List<UnorderedPair<Integer, Integer>> squareIsingEdges(int N) {
    val result = new ArrayList
    for (int i : 0 ..< N) {
      for (int j : 0 ..< N-1){
        result.add(new UnorderedPair(N*i+j, N*i+j+1))
      }
      result.add(new UnorderedPair(N*i,N*i+N-1))
    }
    for (int j : 0 ..< N) {
      for (int i : 0 ..< N-1) {
        result.add(new UnorderedPair(N*i+j, N*(i+1)+j))
      }
      result.add(new UnorderedPair(j,N*(N-1)+j))
    }
    return result
  }
  
  def static List<UnorderedPair<Integer, Integer>> squareIsingEdgesSpatialTemporal(int N, int T) {
    val result = new ArrayList
    for (int t: 0 ..< T) {
      for (int i : 0 ..< N) {
        for (int j : 0 ..< N-1) {
          result.add(new UnorderedPair(t*N*N+N*i+j,t*N*N+N*i+j+1))
        }
      }
      for (int j : 0 ..< N) {
        for (int i : 0 ..< N-1) {
          result.add(new UnorderedPair(t*N*N+N*i+j,t*N*N+N*(i+1)+j))
        }
      }
      if (t<T-1) {
        for (int i : 0 ..< N*N) {
      	  result.add(new UnorderedPair(t*N*N+i,(t+1)*N*N+i))
        }
      }
    }
    return result
  }  
}
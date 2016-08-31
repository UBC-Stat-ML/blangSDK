package blang.utils

import blang.types.IntVar
import java.util.List
import blang.types.RealVar
import blang.types.Simplex
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.Delegate
import java.util.Map
import blang.types.IntVar.IntImpl
import blang.types.RealVar.RealImpl

class ExtensionUtils {
  
  def static RealVar createLatentReal(double initialValue) { 
    return new RealImpl(initialValue)
  }
  
  def static IntVar createLatentInt(int initialValue) { 
    return new IntImpl(initialValue)
  }
  
  def static List<IntVar> listOfIntVars(int size) {
    val List<IntVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(createLatentInt(0))
    }
    return result
  }
  
    def static List<RealVar> listOfRealVars(int size) {
    val List<RealVar> result = new ArrayList
    for (var int i = 0; i < size; i++) {
      result.add(createLatentReal(0.0))
    }
    return result
  }
  
  def static <T> T get(List<T> list, IntVar intVar) {
    return list.get(intVar.intValue)
  }
  
  def static double get(Simplex simplex, IntVar intVar) {
    return simplex.get(intVar.intValue)
  }
  
  def static double exp(RealVar realVar) {
    return Math::exp(realVar.doubleValue)
  }
  
  
  def static <K1,K2,V> V get(Map<K1,Map<K2,V>> map, K1 key1, K2 key2) {
    return map.get(key1).get(key2)
  }
  
  @Data
  static class Table_2D<K1, K2, V> implements Map<K1,Map<K2,V>> {
    
    @Delegate
    val Map<K1,Map<K2,V>> value
    
  }
  
  @Data
  static class Table_3D<K1, K2, K3, V> implements Map<K1,Map<K2,Map<K3,V>>> {
    
    @Delegate
    val Map<K1,Map<K2,Map<K3,V>>> value
    
  }
  
  
  
//  def static <T> T get(List<List<T>> list, int i, int j) {
//    return list.get(i).get(j)
//  }
//  
//  @Data
//  static class Array_2D<T> implements List<List<T>> {
//    
//    @Delegate
//    val List<List<T>> value
//    
//  }
//  
//  @Data
//  static class Array_3D<T> implements List<List<List<T>>> {
//    
//    @Delegate
//    val List<List<List<T>>> value
//    
//  }
//  
  def public static void main(String [] args) {
    
    val Table_3D<String, String, String, Integer> table = null
    
    val Map<String,Integer> res = table.get("asdf", "asdf")
    
//    val Array_3D<String> list = new Array_3D(null)
//    val List<String> test = list.get(0,0)
    
  }
  
//  def static boolean >=(IntVar v0, int v1) {
//    return v0.intValue >= v1
//  }
//  
//    def static boolean <=(IntVar v0, int v1) {
//    return v0.intValue <= v1
//  }
//  
//    def static boolean >(IntVar v0, int v1) {
//    return v0.intValue > v1
//  }
//  
//    def static boolean <(IntVar v0, int v1) {
//    return v0.intValue < v1
//  }
  
}
package blangProjectTemplate

import org.eclipse.xtend.lib.annotations.Data

@Data
class PTQuickTest {
  
  val double p0 = 0.0001
  val double p1 = 0.9999
  val int N
  
  def double T(int i) {
    return (i as double) / (N as double)
  }
  
  def double pr(boolean s, double p) {
   if (s) 
     return p 
   else 
     return (1.0 - p)
  }
  
  def double pr(int i, boolean s) {
    return (1.0 - T(i)) * pr(s, p0) + T(i) * pr(s, p1)
//    val prT = p ** T(i)
//    val prF = (1.0-p) ** T(i)
//    return (if (s) prT else prF) / (prT + prF)
  }
  
  def double A(int i) {
    var double sum = 0.0
    for (s1 : #[true, false]) {
      for (s2 : #[true, false]) {
        sum += Math.min(pr(i, s1) * pr(i+1,s2), pr(i, s2) * pr(i+1,s1))
//        val double ratio = pr()//(pr(s1) / pr(s2)) ** (T(i+1) - T(i))
//        sum += Math.min(1, ratio) * pr(i, s1) * pr(i+1, s2)
      }
    }
    return sum
  }
  
  def double A() {
    var double product = 1.0
    for (int i : 0 ..< N) {
      System.out.print(A(i) + " ")
      product *= A(i)
    }
    System.out.println
    return product
  }
  
  def static void main(String [] args) {
    for (int i : 0 ..< 5) {
      var int nChains = (2 ** i) as int
      println(nChains)
      println("pr = " + new PTQuickTest(nChains).A)
    }
  }
}
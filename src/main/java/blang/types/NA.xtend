package blang.types

class NA {
  
  /**
   * A symbol used when parsing variables to indicate the 
   * value is not observed (and hence needs to be 
   * imputed as part of the posterior simulation).
   */
  val public static SYMBOL = "NA"
  
  private new () {}
}
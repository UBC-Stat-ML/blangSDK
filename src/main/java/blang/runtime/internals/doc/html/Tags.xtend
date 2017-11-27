package blang.runtime.internals.doc.html

import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

class Tags {
  
  def static a(Procedure1<A> init) { new A => init }
  def static div(Procedure1<? super Div> init) { new Div => init }
  def static li(Procedure1<Li> init) { new Li => init }
  def static nav(Procedure1<Nav> init) { new Nav => init } 
  def static ul(Procedure1<Ul> init) { new Ul => init }
  def static h1(Procedure1<H1> init) { new H1 => init }
  def static h2(Procedure1<H2> init) { new H2 => init }
  def static h3(Procedure1<H3> init) { new H3 => init }
  
  private new() {}
}
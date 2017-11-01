package blang.tests;

import org.junit.Test;

import blang.core.LogScaleFactor;
import blang.core.ModelBuilder;
import blang.tests.fixtures.AutoBoxDeboxTests;
import blang.tests.fixtures.Operations;

public class TestSyntax 
{
  @Test
  public void boxDebox() 
  {
    test(new AutoBoxDeboxTests.Builder());
  }
  
  @Test
  public void operations()
  {
    test(new Operations.Builder());
  }
  
  private static void test(ModelBuilder builder) 
  {
    ((LogScaleFactor) builder.build().components().iterator().next()).logDensity();
  }
}

package blang;

import org.junit.Test;

import blang.core.LogScaleFactor;
import blang.core.ModelBuilder;
import blang.validation.internals.fixtures.AutoBoxDeboxTests;
import blang.validation.internals.fixtures.Operations;

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

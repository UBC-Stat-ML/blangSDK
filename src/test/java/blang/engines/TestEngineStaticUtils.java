package blang.engines;

import java.util.Arrays;

import org.junit.Assert;
import org.junit.Test;

import bayonet.distributions.Random;
import bayonet.math.NumericalUtils;
import blang.engines.internals.EngineStaticUtils;

public class TestEngineStaticUtils 
{
  @Test
  public void testAvg() 
  {
    int n = 25;
    Random rand = new Random(1);
    double [] ns = new double[n];
    
    for (int i = 0; i < n; i++)
      ns[i] = rand.nextDouble();
    
    Arrays.sort(ns);
    
    Assert.assertEquals(naiveAverageDifference(ns), EngineStaticUtils.averageDifference(ns), NumericalUtils.THRESHOLD);
  }
  
  public static double naiveAverageDifference(double [] numbers) 
  {
    double sum = 0.0;
    for (int i = 0; i < numbers.length; i++)
      for (int j = 0; j < numbers.length; j++)
        sum += Math.abs(numbers[i] - numbers[j]);
    return sum / numbers.length / numbers.length;
  }
}

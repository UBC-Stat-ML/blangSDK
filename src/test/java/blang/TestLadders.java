package blang;

import java.io.File;
import java.util.Arrays;
import java.util.List;

import org.junit.Assert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import blang.engines.internals.ladders.EquallySpaced;
import blang.engines.internals.ladders.FromAnotherExec;
import blang.engines.internals.ladders.Geometric;
import blang.engines.internals.ladders.Polynomial;
import blang.engines.internals.ladders.TemperatureLadder;
import blang.engines.internals.ladders.UserSpecified;
import blang.runtime.Runner;
import blang.validation.internals.fixtures.Doomsday;

public class TestLadders
{
  
  @Test
  public void test() 
  {
    List<TemperatureLadder> ladders = Arrays.asList(
        new EquallySpaced(), 
        new Geometric(), 
        new Polynomial(), 
        userSpecified(), 
        userSpecified2(true), 
        fromEarlier());

    for (TemperatureLadder ladder : ladders)
    {
      Assert.assertEquals(ladder.temperingParameters(4).size(), 4);
      System.out.println(ladder.temperingParameters(4));
    }
    
  }
  
  @Test
  public void testOneChain() 
  {
    List<TemperatureLadder> ladders = Arrays.asList(
        new EquallySpaced(), 
        new Geometric(), 
        new Polynomial(), 
        //userSpecified(),  // this one by design will not work with one chain
        userSpecified2(true), 
        fromEarlier());


    for (TemperatureLadder ladder : ladders)
    {
      Assert.assertEquals(ladder.temperingParameters(1).size(), 1);
      System.out.println(ladder.temperingParameters(1));
    }
    
  }
  
  @Test
  public void testErrorCatch() 
  {
    try {
      userSpecified2(false).temperingParameters(4);
    } catch (RuntimeException e) 
    {
      return;
    }
    Assert.assertEquals(1, 0); 
  }
  

  private UserSpecified userSpecified()
  {
    UserSpecified result = new UserSpecified();
    result.annealingParameters = Arrays.asList(0.0, 0.2, 0.4, 1.0);
    return result;
  }
  
  private UserSpecified userSpecified2(boolean allows)
  {
    UserSpecified result = new UserSpecified();
    result.annealingParameters = Arrays.asList(0.0, 0.1, 0.2, 0.3, 0.4, 0.9, 0.94, 1.0);
    result.allowSplineGeneralization = allows;
    return result;
  }
  
  @Rule
  public TemporaryFolder folder= new TemporaryFolder();
  
  private FromAnotherExec fromEarlier() 
  {
    blang.System.out.maxIndentationToPrint = -1;
    File execFolder = folder.getRoot();
    Runner r = Runner.create(execFolder, 
        "--model", Doomsday.class.getCanonicalName(),
        "--model.rate", "1.0",
        "--model.z", "NA",
        "--model.y", "1.2"
      );
    r.run();
    File monitoring = new File(execFolder, "monitoring");
    File annealingParams = new File(monitoring, "annealingParameters.csv");
    FromAnotherExec result = new FromAnotherExec();
    result.annealingParameters = annealingParams;
    result.allowSplineGeneralization = true;
    return result;
  }
}

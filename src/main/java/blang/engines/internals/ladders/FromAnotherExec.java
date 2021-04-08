package blang.engines.internals.ladders;

import static blang.inits.experiments.tabwriters.TidySerializer.VALUE;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import blang.inits.Arg;
import blang.inits.DefaultValue;
import briefj.BriefIO;

public class FromAnotherExec implements TemperatureLadder
{
  @Arg   @DefaultValue("An 'annealingParameters.csv[.gz] file from the monitoring folder "
      + "of an ealier execution. The schedule from the final round will be used as the initialiation "
      + "of this one. ")
  public File annealingParameters;
  
  @Arg(description = "If the command line argument 'nChains' is different, than the number of "
      + "provided grid points, allow the use of spline interpolation/extrapolation.")                        
                              @DefaultValue("false")
  public boolean allowSplineGeneralization = false;
  
  @Override
  public List<Double> temperingParameters(int nChains) 
  { 
    List<Double> parsed = new ArrayList<Double>();
    parsed.add(0.0);
    for (Map<String,String> line : BriefIO.readLines(annealingParameters).indexCSV())
      if (line.get("isAdapt").equals("false"))
      {
        parsed.add(Double.parseDouble(line.get(VALUE)));
      }
    UserSpecified userSpecified = new UserSpecified();
    userSpecified.annealingParameters = parsed;
    userSpecified.allowSplineGeneralization = this.allowSplineGeneralization;
    return userSpecified.temperingParameters(nChains);
  }
  
}

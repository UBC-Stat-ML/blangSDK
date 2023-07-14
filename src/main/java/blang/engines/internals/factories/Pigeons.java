package blang.engines.internals.factories;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import bayonet.distributions.Random;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;

/**
 * Used to run Blang over MPI. 
 * 
 * Interface with Pigeons (https://github.com/Julia-Tempering/Pigeons.jl)
 * Do not call directly, instead invoked by a Pigeons process orchestrating 
 * MPI communication. 
 */
public class Pigeons implements PosteriorInferenceEngine
{
  @Arg
  public Random random;
  
  @Arg            @DefaultValue("3")
  public double nPassesPerScan = 3;
  
  SampledModel model;

  public static String LOG_POTENTIAL_CODE = "log_potential(";
  public static String CALL_SAMPLER_CODE  = "call_sampler!(";

  @Override
  public void performInference()
  {
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    try {
      while (true)
      {
        String line = br.readLine();
        if (line == null)
          return;
        if (line.startsWith(LOG_POTENTIAL_CODE))
                            log_potential(parseAnnealingParameter(line, 
                            LOG_POTENTIAL_CODE)); 
        else 
        if (line.startsWith(CALL_SAMPLER_CODE))
                            call_sampler(parseAnnealingParameter(line, 
                            CALL_SAMPLER_CODE));
      }
    } catch (Exception ioe) {  
      throw new RuntimeException(ioe);
    }
  }
  
  private void call_sampler(double annealingParam)
  {
    model.setExponent(annealingParam);
    if (annealingParam == 0.0)
      model.forwardSample(random, false);
    else
      model.posteriorSamplingScan(random, nPassesPerScan);
    System.out.println("response()");
  }

  private void log_potential(double annealingParam)
  {
    double result = model.logDensity(annealingParam);
    System.out.println("response(" + result + ")");
  }
  
  public double parseAnnealingParameter(String line, String code) 
  {
    String annealingParamString = line.substring(code.length(), line.length() - 1); // -1 for final parenthesis
    return Double.parseDouble(annealingParamString);
  }

  @Override
  public void setSampledModel(SampledModel model)
  {
    this.model = model;
  }
  
  @Override
  public void check(GraphAnalysis analysis) {}
}

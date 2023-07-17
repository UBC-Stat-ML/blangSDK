package blang.engines.internals.factories;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;

import bayonet.distributions.Random;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
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
  @GlobalArg public ExperimentResults results = new ExperimentResults();
  
  @Arg
  public Long random;
  
  public Random rng = null;
  
  @Arg            @DefaultValue("3")
  public double nPassesPerScan = 3;
  
  public boolean log = true; // TODO: default should be false!!
  private BufferedWriter logger = null;
  
  SampledModel model;

  public static String LOG_POTENTIAL_CODE = "log_potential(";
  public static String CALL_SAMPLER_CODE  = "call_sampler!(";
 
  
  public static <T> T static_log(T object) {
    return instance.log(object);
  }
  
  public <T> T log(T object) 
  {
    if (log)
    {
      String msg = "[time=" + System.currentTimeMillis() + ",seed=" + random + "] " + object.toString();
      if (logger == null)
        logger = results.getAutoClosedBufferedWriter("log.txt");
      try
      {
        logger.append(msg + "\n");
        logger.flush();
      } catch (IOException e)
      {
        e.printStackTrace();
      }
    }
    return object;
  }
  
  static Pigeons instance = null;

  @Override
  public void performInference()
  {
    instance = this;
    if (rng == null)
      rng = new Random(random);
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    try {
      while (true)
      {
        String line = br.readLine();
        log("input=" + line);
        if (line == null)
          return;
        if (line.startsWith(LOG_POTENTIAL_CODE))
                            log_potential(parseAnnealingParameter(line, 
                            LOG_POTENTIAL_CODE)); 
        else if (line.startsWith(CALL_SAMPLER_CODE))
                            call_sampler(parseAnnealingParameter(line, 
                            CALL_SAMPLER_CODE));
        else
          throw new RuntimeException();
      }
    } catch (Exception ioe) {  
      throw new RuntimeException(ioe);
    }
  }
  
  private void call_sampler(double annealingParam)
  {
    model.setExponent(annealingParam);
    log("call_sampler logd_before=" + model.logDensity());
    if (annealingParam == 0.0)
      model.forwardSample(rng, false);
    else
      model.posteriorSamplingScan(rng, nPassesPerScan);
    System.out.println("response()");
    log("call_sampler logd_after=" + model.logDensity());
  }
  
  

  private void log_potential(double annealingParam)
  {
    double result = model.logDensity(annealingParam);
    System.out.println("response(" + result + ")");
    log("log_potential logd=" + result);
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

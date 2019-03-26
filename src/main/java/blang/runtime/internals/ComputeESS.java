package blang.runtime.internals;

import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import com.google.common.base.Joiner;

import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.experiments.Experiment;
import blang.inits.experiments.tabwriters.TidySerializer;
import blang.runtime.Runner;
import briefj.BriefIO;
import briefj.BriefMaps;
import briefj.CSV;

public class ComputeESS extends Experiment 
{
  @Arg(description = "csv file containing samples")
  public File inputFile;
  
  @Arg(description = "Look for this column name for samples.") 
                  @DefaultValue(TidySerializer.VALUE)
  public String samplesColumn = TidySerializer.VALUE;
  
  @Arg(description = "Look for this column name for iteration index (or empty if none).")
                         @DefaultValue(Runner.sampleColumn)
  public String iterationIndexColumn = Runner.sampleColumn;
  
  @Arg        @DefaultValue("1")
  public int moment        = 1;
         
  @Arg            @DefaultValue("0.5")
  public double burnInFraction = 0.5;
  
  @Arg     @DefaultValue("ess.csv")
  public String output = "ess.csv";
  
  @Arg                          @DefaultValue("BATCH")
  public EssEstimator estimator = EssEstimator.BATCH;
  
  public static enum EssEstimator { 
    BATCH { 
      public double ess(List<Double> samples) { return bayonet.math.EffectiveSampleSize.ess(samples);}
    }, 
    ACT { @SuppressWarnings("deprecation")
      public double ess(List<Double> samples) { return bayonet.math.AutoCorrTime.ess(samples);}
    },
    AR { @SuppressWarnings("deprecation")
      public double ess(List<Double> samples) { return bayonet.coda.EffectiveSize.effectiveSize(samples);}
    };
    public abstract double ess(List<Double> samples);
  }

  @Override
  public void run() { try { computeEss(); } catch (Exception e) { throw new RuntimeException(e); } }
    
  public void computeEss() throws IOException
  {
    if (burnInFraction < 0.0 || burnInFraction > 1.0)
      throw new RuntimeException();
    Map<Map<String,String>,List<Double>> samples = new LinkedHashMap<>();
    for (Map<String,String> line : BriefIO.readLines(inputFile).indexCSV()) {
      double value = Double.parseDouble(line.get(samplesColumn).trim());
      line.remove(samplesColumn);
      line.remove(iterationIndexColumn);
      BriefMaps.getOrPutList(samples, line).add(value);
    }
    BufferedWriter writer = results.getAutoClosedBufferedWriter(output);
    {
      List<String> header = new ArrayList<>(samples.keySet().iterator().next().keySet());
      header.add("ess");
      writer.append(CSV.toCSV(header) + "\n");
    }
    for (Map<String,String> key : samples.keySet()) {
      List<Double> curSamples = samples.get(key);
      double ess = estimator.ess(
          curSamples.subList((int) (burnInFraction * curSamples.size()), curSamples.size())
            .stream().map(x -> Math.pow(x, moment))
            .collect(Collectors.toList())); 
      List<String> entries = new ArrayList<>(key.values());
      entries.add("" +  ess);
      writer.append(CSV.toCSV(entries) + "\n");
    }
  }

  public static void main(String [] args) 
  {
    Experiment.startAutoExit(args);
  }
}

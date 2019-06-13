package blang.runtime.internals;

import java.io.BufferedWriter;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.eclipse.xtext.xbase.lib.Pair;

import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.Implementations;
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
  
  @Arg                 @DefaultValue("Batch")
  public EssEstimator estimator = new Batch();
  
  @Implementations({Batch.class, ACT.class, AR.class})
  public static interface EssEstimator 
  {
    public double ess(Map<String,String> key, List<Double> samples);
  }
  
  public static class Batch implements EssEstimator 
  {
    @Arg(description = "csv file containing reference values for the mean and sd")
    public Optional<File> referenceFile = Optional.empty();
    
    @Arg(description = "Look for this column name for reference mean.") 
                          @DefaultValue("mean")
    public String referenceMeanColumn = "mean";

    @Arg(description = "Look for this column name for reference sd.") 
                        @DefaultValue("sd")
    public String referenceSDColumn = "sd";
    
    @Override
    public double ess(Map<String,String> key, List<Double> samples) 
    {
      if (referenceFile.isPresent()) {
        Pair<Double,Double> meanAndSD = findMeanSD(key);
        return bayonet.math.EffectiveSampleSize.ess(samples, meanAndSD.getKey(), meanAndSD.getValue());
      } 
      else
        return bayonet.math.EffectiveSampleSize.ess(samples);
    }

    // Note: do not cache this, since it is used with different files in DefaultPostProcessor
    private Pair<Double, Double> findMeanSD(Map<String, String> keys) 
    {
      Pair<Double, Double> found = null;
      for (Map<String,String> entry : BriefIO.readLines(referenceFile.get()).indexCSV()) {
        // try to match
        String meanStr = entry.get(referenceMeanColumn);
        String sdStr = entry.get(referenceSDColumn);
        if (meanStr == null || sdStr == null) 
          throw new RuntimeException("Reference file does not contain expected columns " + referenceMeanColumn + " and " + referenceSDColumn);
        Pair<Double,Double> candidate = Pair.of(
            Double.parseDouble(meanStr), 
            Double.parseDouble(sdStr));
        entry.keySet().retainAll(keys.keySet());
        if (entry.equals(keys))
        {
          if (found != null)
            throw new RuntimeException("Duplicate reference for " + keys);
          found = candidate;
        }
      }
      if (found == null) 
        throw new RuntimeException("Key not found in reference file: " + keys);
      return found;
    }
  }
  
  public static class ACT implements EssEstimator 
  { 
    @SuppressWarnings("deprecation")
    @Override
    public double ess(Map<String,String> key, List<Double> samples) 
    { 
      return bayonet.math.AutoCorrTime.ess(samples);
    }
  }
  
  public static class AR implements EssEstimator 
  { 
    @SuppressWarnings("deprecation")
    @Override
    public double ess(Map<String,String> key, List<Double> samples) 
    { 
      return bayonet.coda.EffectiveSize.effectiveSize(samples);
    }
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
      if (!line.containsKey(samplesColumn) || !line.containsKey(iterationIndexColumn))
        throw new RuntimeException("File " + inputFile.getAbsolutePath() + " should contain columns named " + samplesColumn + " and " + iterationIndexColumn);
      line.remove(samplesColumn);
      line.remove(iterationIndexColumn);
      BriefMaps.getOrPutList(samples, line).add(value);
    }
    BufferedWriter writer = results.getAutoClosedBufferedWriter(output);
    {
      List<String> header = new ArrayList<>(samples.keySet().iterator().next().keySet());
      header.add(TidySerializer.VALUE);
      writer.append(CSV.toCSV(header) + "\n");
    }
    for (Map<String,String> key : samples.keySet()) {
      List<Double> curSamples = samples.get(key);
      double ess = estimator.ess(key, 
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

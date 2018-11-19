package blang.engines.internals.factories;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.xtext.xbase.lib.Pair;

import com.google.common.primitives.Doubles;

import bayonet.distributions.Random;
import blang.engines.ParallelTempering;
import blang.engines.internals.EngineStaticUtils;
import blang.engines.internals.PosteriorInferenceEngine;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.GlobalArg;
import blang.inits.experiments.ExperimentResults;
import blang.inits.experiments.tabwriters.TabularWriter;
import blang.io.BlangTidySerializer;
import blang.runtime.Runner;
import blang.runtime.SampledModel;
import blang.runtime.internals.objectgraph.GraphAnalysis;
import briefj.BriefMaps;

public class PT extends ParallelTempering implements PosteriorInferenceEngine  
{
  @GlobalArg public ExperimentResults results = new ExperimentResults();
  
  @Arg @DefaultValue("1_000")
  public int nScans = 1_000;
  
  @Arg         @DefaultValue("3")
  public double nPassesPerScan = 3;
  
  @Arg               @DefaultValue("1")
  public Random random = new Random(1);
  
  @Override
  public void setSampledModel(SampledModel model) 
  {
    initialize(model, random);
  }
  
  public Map<Double,Double> lambdaMCEstimates = null;

  public static final String
    energyFileName = "energy",
    logDensityFileName = "logDensity",
    allLogDensitiesFileName = "allLogDensities",
    swapIndicatorsFileName = "swapIndicators",
    swapStatisticsFileName = "swapStatistics",
    sampleColumn = "sample",
    chainColumn = "chain",
    acceptPrColumn = "acceptPr",
    lambdaMCacceptPr = "lambdaMCacceptPr",
    annealingParameterColumn = "annealingParameter";
  
  @SuppressWarnings("unchecked")
  @Override
  public void performInference() 
  {
    BlangTidySerializer tidySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    BlangTidySerializer densitySerializer = new BlangTidySerializer(results.child(Runner.SAMPLES_FOLDER)); 
    BlangTidySerializer swapIndicatorSerializer = new BlangTidySerializer(results.child(Runner.MONITORING_FOLDER));  
    Map<Double,List<Double>> energies = new LinkedHashMap<>();
    for (int iter = 0; iter < nScans; iter++)
    {
      moveKernel(nPassesPerScan);
      for (int i = 0; i < temperingParameters.size(); i++)  
      {
        final Double temperingParam =  temperingParameters.get(i);
        densitySerializer.serialize(states[i].logDensity(), allLogDensitiesFileName, 
            Pair.of(sampleColumn, iter), 
            Pair.of(chainColumn, i),
            Pair.of(annealingParameterColumn, temperingParam));
        final double energy = -states[i].preAnnealedLogLikelihood();
        densitySerializer.serialize(energy, energyFileName, 
            Pair.of(sampleColumn, iter), 
            Pair.of(chainColumn, i),
            Pair.of(annealingParameterColumn, temperingParam));
        BriefMaps.getOrPutList(energies, temperingParam).add(energy);
      }
      densitySerializer.serialize(getTargetState().logDensity(), logDensityFileName, 
          Pair.of(sampleColumn, iter));
      getTargetState().getSampleWriter(tidySerializer).write(
          Pair.of(sampleColumn, iter));
      boolean[] swapIndicators = swapKernel();
      for (int c = 0; c < nChains(); c++)
        swapIndicatorSerializer.serialize(swapIndicators[c] ? 1 : 0, swapIndicatorsFileName, 
            Pair.of(sampleColumn, iter), 
            Pair.of(chainColumn, c),
            Pair.of(annealingParameterColumn, temperingParameters.get(c)));
    }
    lambdaMCEstimates = computeLambdaMCEstimate(energies);
    reportAcceptanceRatios(lambdaMCEstimates);
  }
  
  public static Map<Double,Double> computeLambdaMCEstimate(Map<Double,List<Double>> energies)
  {
    Map<Double,Double> result = new LinkedHashMap<Double, Double>();
    for (double annealingParam : energies.keySet()) 
    {
      double [] sortedCopy = Doubles.toArray(energies.get(annealingParam));
      Arrays.sort(sortedCopy);
      double lambda = 0.5 * EngineStaticUtils.averageDifference(sortedCopy);
      result.put(annealingParam, lambda);
    }
    return result;
  }

  private void reportAcceptanceRatios(Map<Double,Double> mcEstimates) 
  {
    TabularWriter tabularWriter = results.child(Runner.MONITORING_FOLDER).getTabularWriter(swapStatisticsFileName);
    for (int i = 0; i < nChains() - 1; i++)
      tabularWriter.write(
          Pair.of(chainColumn, i), 
          Pair.of(annealingParameterColumn, temperingParameters.get(i)), 
          Pair.of(lambdaMCacceptPr, 1.0 - (temperingParameters.get(i) - temperingParameters.get(i + 1)) * mcEstimates.get(temperingParameters.get(i))),
          Pair.of(acceptPrColumn, swapAcceptPrs[i].getMean()));
  }

  @Override
  public void check(GraphAnalysis analysis) 
  {
    // TODO: may want to check forward simulators ok
    return;
  }
}

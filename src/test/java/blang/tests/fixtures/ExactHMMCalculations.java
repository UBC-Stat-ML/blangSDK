package blang.tests.fixtures;

import java.util.List;

import org.jgrapht.UndirectedGraph;

import bayonet.distributions.Multinomial;
import bayonet.graphs.GraphUtils;
import bayonet.marginal.DiscreteFactorGraph;
import bayonet.marginal.algo.SumProduct;
import blang.inits.Arg;
import blang.inits.DefaultValue;
import blang.inits.DesignatedConstructor;
import blang.inits.Implementations;

public class ExactHMMCalculations 
{
  @Arg                @DefaultValue("SimpleThreeStates")
  public Parameters parameters = new SimpleThreeStates();
  
  @Arg @DefaultValue("2")
  public    int len = 2;

  public double computeLogZ(List<Integer> observations)
  { 
    transitionPrs = parameters.transitionPrs();
    emissionPrs = parameters.emissionPrs();
    initialPrs = parameters.initialPrs();
    dfg = createHMM(observations);
    sp = new SumProduct<>(dfg);
    return sp.logNormalization();
  }
  
  double [][] transitionPrs = null;
  double [][] emissionPrs = null;
  double [] initialPrs = null;
  List<Integer> observations = null;
  DiscreteFactorGraph<Integer> dfg;
  SumProduct<Integer> sp;
  
  DiscreteFactorGraph<Integer> createHMM(List<Integer> observations)
  {
    UndirectedGraph<Integer, ?> topology = GraphUtils.createChainTopology(len);
    DiscreteFactorGraph<Integer> result = new DiscreteFactorGraph<Integer>(topology);
    
    // initial distribution
    result.setUnary(0, new double[][]{initialPrs});
    
    // transition
    for (int i = 0; i < len-1; i++)
      result.setBinary(i, i+1, transitionPrs);
    
    // observations
    for (int i = 0; i < len; i++)
    {
      int currentObs = observations.get(i);
      double [] curEmissionPrs = new double[initialPrs.length];
      for (int s = 0; s < initialPrs.length; s++)
        curEmissionPrs[s] = emissionPrs[s][currentObs];
      result.unaryTimesEqual(i, new double[][]{curEmissionPrs});
    }
    
    return result;
  }
  
  @Implementations({SimpleThreeStates.class, SimpleTwoStates.class, LowPrValley.class})
  static interface Parameters
  {
    double [][] transitionPrs();
    double [][] emissionPrs();
    double [] initialPrs();
  } 
  
  public static class LowPrValley implements Parameters
  {
    @Arg     @DefaultValue("0.01")
    public double epsilon = 0.01;

    @Override
    public double[][] transitionPrs()
    {
      double [][] result = new double[5][5];
      for (int i = 0; i < 5; i++)
        for (int j = 0; j < 5; j++)
          if (Math.abs(i - j) < 2)
            result[i][j] = 1.0;
      for (int r = 0; r < 5; r++)
        Multinomial.normalize(result[r]);
      return result;
    }

    @Override
    public double[][] emissionPrs()
    {
      double [][] result = new double[5][];
      if (epsilon >= 1.0)
        throw new IllegalArgumentException();
      result[0] = result[3] = new double[]{0.2, 0.8};
      result[1] = new double[]{0.1, 0.9};
      result[4] = new double[]{0.3, 0.7};
      result[2] = new double[]{epsilon, 1.0 - epsilon};
      return result;
    }

    @Override
    public double[] initialPrs()
    {
      double [] result = new double[5];
      for (int i = 0; i < 5; i++)
        result[i] = 1.0/5.0;
      return result;
    }
  }
  
  public static class SimpleThreeStates implements Parameters
  {
    @DesignatedConstructor
    public SimpleThreeStates() {}
    
    @Override
    public double[][] transitionPrs()
    {
      return new double[][]{{0.8,0.15,0.05},{0.02,0.93,0.05},{0.15,0.15,0.7}};
    }
    @Override
    public double[][] emissionPrs()
    {
      return transitionPrs();
    }
    @Override
    public double[] initialPrs()
    {
      return new double[]{0.25, 0.25, 0.5};
    }
  }
  
  public static class SimpleTwoStates implements Parameters
  {
    @DesignatedConstructor
    public SimpleTwoStates() {}
    
    @Override
    public double[][] transitionPrs()
    {
      return new double[][]{{0.1, 0.9},{0.6, 0.4}};
    }
    @Override
    public double[][] emissionPrs()
    {
      return transitionPrs();
    }
    @Override
    public double[] initialPrs()
    {
      return new double[]{0.2, 0.8};
    }
  }

}

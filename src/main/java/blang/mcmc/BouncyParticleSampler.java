package blang.mcmc;

import static ca.ubc.bps.factory.BPSFactoryHelpers.noInit;

import java.util.ArrayList;
import java.util.Collection;
import java.util.IdentityHashMap;
import java.util.List;

import bayonet.distributions.Random;
import blang.core.LogScaleFactor;
import blang.core.RealVar;
import blang.core.WritableRealVar;
import blang.distributions.NormalField;
import blang.mcmc.internals.SamplerBuilderContext;
import blang.runtime.internals.objectgraph.Node;
import blang.runtime.internals.objectgraph.StaticUtils;
import blang.types.Index;
import blang.types.Plate;
import blang.types.Plated;
import blang.types.Precision;
import briefj.Indexer;
import briefj.collections.UnorderedPair;
import ca.ubc.bps.BPSPotential;
import ca.ubc.bps.energies.Energy;
import ca.ubc.bps.energies.NormalEnergy;
import ca.ubc.bps.energies.NumericalEnergy;
import ca.ubc.bps.factory.BPSFactory;
import ca.ubc.bps.factory.BPSFactory.BPS;
import ca.ubc.bps.factory.ModelBuildingContext;
import ca.ubc.bps.models.Model;
import ca.ubc.bps.state.Dynamics;
import ca.ubc.bps.state.MutableDouble;
import ca.ubc.bps.state.PiecewiseLinear;
import ca.ubc.bps.state.PositionVelocity;
import ca.ubc.bps.state.PositionVelocityDependent;
import ca.ubc.bps.state.SimpleMutableDouble;
import ca.ubc.bps.timers.NormalClock;
import ca.ubc.bps.timers.QuasiConvexTimer;
import ca.ubc.bps.timers.QuasiConvexTimer.Optimizer;
import ca.ubc.pdmp.Clock;
import ca.ubc.pdmp.Coordinate;
import ca.ubc.pdmp.DeltaTime;
import ca.ubc.pdmp.PDMP;
import ca.ubc.pdmp.PDMPSimulator;
import ca.ubc.pdmp.StoppingCriterion;
import cern.colt.Arrays;
import xlinear.Matrix;
import xlinear.MatrixOperations;

public class BouncyParticleSampler<K> implements Sampler 
{
  @SampledVariable(skipFactorsFromSampledModel = true)
  public NormalField field;
  
  @ConnectedFactor
  public List<LogScaleFactor> likelihoods;
  
  PDMPSimulator simulator;
  final boolean useLocal = true;

  @Override
  public void execute(Random rand) 
  { 
    // TODO: check sparsity structure did not change
    simulator.simulate(rand, StoppingCriterion.byStochasticProcessTime(1.0));
  }

  @Override
  public boolean setup(SamplerBuilderContext context) 
  {
    BPSFactory bpsFactory = new BPSFactory();
    bpsFactory.results = context.monitoringStatistics;
    bpsFactory.initialization = noInit;
    bpsFactory.model = new BlangModelAdaptor(context);

    // TODO: cache the sparsity structure and check again later
    
    BPS bps = bpsFactory.buildBPS();
    PDMP pdmp = bps.getPDMP();
    simulator = new PDMPSimulator(pdmp);
    simulator.setPrintSummaryStatistics(false); 
    return true;
  }
  
  private class BlangModelAdaptor implements Model 
  {
    SamplerBuilderContext blangContext;
    BlangModelAdaptor(SamplerBuilderContext blangContext) 
    {
      this.blangContext = blangContext;
    }

    @Override
    public void setup(ModelBuildingContext bpsContext, boolean initializeStatesFromStationary) 
    {
      if (initializeStatesFromStationary)
        throw new RuntimeException();
      
      if (!(bpsContext.dynamics() instanceof PiecewiseLinear)) // && 
         // !(bpsContext.dynamics() instanceof IsotropicHamiltonian))
        throw new RuntimeException();
      
      // prepare indexing and variable adaptors
      @SuppressWarnings("unchecked")
      Precision<K> precision = (Precision<K>) field.getPrecision();
      Indexer<K> indexer = Precision.indexer(precision.getPlate());
      IdentityHashMap<WritableRealVar, PositionVelocity> realVar2PosVel = new IdentityHashMap<>();
      @SuppressWarnings("unchecked")
      List<PositionVelocity> variables = buildArray(indexer, field.getPrecision().getPlate(), field.getRealization(), bpsContext.dynamics, realVar2PosVel);
      bpsContext.registerPositionVelocityCoordinates(variables);
      
      // likelihood
      for (LogScaleFactor factor : likelihoods) 
      {
        List<WritableRealVar> realVars = new ArrayList<WritableRealVar>();
        for (Node node : blangContext.sampledObjectsAccessibleFrom(factor)) 
        {
          WritableRealVar realVar = StaticUtils.tryCasting(node, WritableRealVar.class);
          if (realVar != null)
            realVars.add(realVar);
        }
        if (!realVars.isEmpty())
        {
          List<PositionVelocity> coordinates = convert(realVars, realVar2PosVel);
          Energy energy = new BlangEnergy(coordinates, factor);
          QuasiConvexTimer timer = new QuasiConvexTimer(coordinates, energy, Optimizer.NAIVE_LINE_SEARCH);
          bpsContext.registerBPSPotential(new BPSPotential(energy, timer));
        }
      }
      
      // prior
      for (UnorderedPair<K, K> key : precision.support())
      {
        PositionVelocity 
          pv0 = variables.get(indexer.o2i(key.getFirst())),
          pv1 = variables.get(indexer.o2i(key.getSecond()));
        
        List<PositionVelocity> coordinates = new ArrayList<>();
        coordinates.add(pv0);
        if (pv0 != pv1)
          coordinates.add(pv1);
        DynamicNormalPotential potAdaptor = new DynamicNormalPotential(key, coordinates);
        BPSPotential potential = new BPSPotential(potAdaptor, potAdaptor);
        bpsContext.registerBPSPotential(potential);
      }
      
      blangContext = null;
    }
  }
  
  private class DynamicNormalPotential implements Clock, Energy 
  {
    @SuppressWarnings("rawtypes")
    private final UnorderedPair key;
    private final List<PositionVelocity> coordinates;
    
    public DynamicNormalPotential(UnorderedPair<K,K> key, List<PositionVelocity> coordinates) 
    {
      this.key = key;
      this.coordinates = coordinates;
    }

    @Override
    public Collection<? extends Coordinate> requiredVariables() 
    {
      return coordinates;
    }

    @Override
    public DeltaTime next(java.util.Random random) 
    {
      NormalClock clock = new NormalClock(coordinates, precision());
      return clock.next(random);
    }
    
    Matrix precision()
    {
      @SuppressWarnings("unchecked")
      double value = field.getPrecision().get(key);
      Matrix precision = MatrixOperations.dense(coordinates.size(), coordinates.size());
      boolean isPair = coordinates.size() == 2;
      if (isPair)
      {
        precision.set(0, 1, value);
        precision.set(1, 0, value); 
      } 
      else 
        precision.set(0, 0, value);
      return precision;
    }
    
    Energy normalEnergy() 
    {
      return new NormalEnergy(precision());
    }

    @Override
    public double[] gradient(double[] point) 
    {
      return normalEnergy().gradient(point);
    }

    @Override
    public double valueAt(double[] point) 
    {
      return normalEnergy().valueAt(point);
    }
  }
  
  private static List<PositionVelocity> convert(
      List<WritableRealVar> realVars,
      IdentityHashMap<WritableRealVar, PositionVelocity> realVar2PosVel) 
  {
    List<PositionVelocity> result = new ArrayList<>();
    for (WritableRealVar realVar : realVars)
      result.add(realVar2PosVel.get(realVar));
    return result;
  }
  
  static <K> List<PositionVelocity> buildArray(
      Indexer<K> indexer, 
      Plate<K> plate, 
      Plated<RealVar> blangVariables, 
      Dynamics dynamics,
      IdentityHashMap<WritableRealVar, PositionVelocity> realVar2PosVel
      )
  {
    List<PositionVelocity> result = new ArrayList<>(indexer.size());
    for (int i = 0; i < indexer.size(); i++)
    {
      Index<K> index = new Index<K>(plate, indexer.i2o(i));
      WritableRealVar blangVariable = (WritableRealVar) blangVariables.get(index);
      PositionVelocity posVel = new PositionVelocity(
        new MutableDoubleRealVarAdaptor(blangVariable), 
        new SimpleMutableDouble(), 
        dynamics, 
        indexer.i2o(i)
      );
      realVar2PosVel.put(blangVariable, posVel);
      result.add(posVel);
    }
    return result;
  }
  
  private static class BlangEnergy extends PositionVelocityDependent implements NumericalEnergy
  {
    private final LogScaleFactor factor;
    
    public BlangEnergy(List<PositionVelocity> requiredVariables, LogScaleFactor factor) 
    {
      super(requiredVariables);
      this.factor = factor;
    }

    @Override
    public double valueAt(double[] point) 
    {
      double [] current = currentPosition();
      setPosition(point);
      double result = - factor.logDensity();
      setPosition(current);
      return result;
    }
  }
  
  private static class MutableDoubleRealVarAdaptor implements MutableDouble
  {
    public final WritableRealVar realVar;
    
    MutableDoubleRealVarAdaptor(WritableRealVar realVar) 
    {
      this.realVar = realVar;
    }

    @Override
    public void set(double value) 
    {
      realVar.set(value);
    }

    @Override
    public double get() 
    {
      return realVar.doubleValue();
    }
  }

}

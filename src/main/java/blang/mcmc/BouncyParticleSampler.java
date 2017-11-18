package blang.mcmc;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import bayonet.distributions.Random;
import blang.core.LogScaleFactor;
import blang.core.WritableRealVar;
//import blang.distributions.NormalField;
import blang.mcmc.internals.SamplerBuilderContext;
import blang.runtime.internals.objectgraph.Node;
import blang.runtime.internals.objectgraph.StaticUtils;

public class BouncyParticleSampler //implements Sampler 
{
//  @SampledVariable(skipFactorsFromSampledModel = true)
//  public NormalField field;
//  
//  @ConnectedFactor
//  public List<LogScaleFactor> likelihoods;
//
//  @Override
//  public void execute(Random rand) 
//  {
//    // TODO Auto-generated method stub
//    
//  }
//
//  @Override
//  public boolean setup(SamplerBuilderContext context) 
//  {
//    for (LogScaleFactor factor : likelihoods) 
//    {
//      List<WritableRealVar> realVars = new ArrayList<WritableRealVar>();
//      for (Node node : context.sampledObjectsAccessibleFrom(factor)) 
//      {
//        WritableRealVar realVar = StaticUtils.tryCasting(node, WritableRealVar.class);
//        if (realVar != null)
//          realVars.add(realVar);
//      }
//      if (!realVars.isEmpty())
//      {
//        xxx
//      }
//    }
//    
//    setup normal factors as well (via field variable above)
//    
//    cache the sparsity structure and check again later
//    
//    return true;
//  }

}

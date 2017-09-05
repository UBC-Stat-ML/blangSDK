package blang.mcmc;


import java.util.List;
import java.util.Random;

import org.apache.commons.math3.util.Pair;

import blang.core.LogScaleFactor;
import blang.core.RealVar;
import blang.core.WritableRealVar;


/**
 * Slice Sampling implemented from 
 * Neal, Radford M. "Slice sampling." Annals of Statistics (2003): 705-741.
 * 
 * Slice sampling boils down to essentially 3 steps.
 * 
 * 1) Identify slice: To avoid underflow, log-values for unnormalizedPotentials is used to determine
 * the "current point". That is, take g(x) = log(f(x)) where f(x) is the unnormalized 
 * potentials. Aux. variable of interest is then: 
 * 
 * z = log(y) = g(x0) - e, e ~ exp(1), 
 * 
 * with slice defined as S = {x : z \leq g(x)}. See p712 for additional discussion. 
 * 
 * 2) Identify interval: Stepping-out procedure is used to locate an interval around the current point. See Fig.3 p714 for alg.
 * 
 * 3) Draw new point x1 from interval: implementing overrelaxed sampling. This procedure avoids random walks, see Section 6 p726.
 * 
 * WARNING: Require re-evaluation of the likelihood for all connected factors many times! 
 * 
 * @author Sean Jewell (jewellsean@gmail.com)
 *
 * Created on Mar 4, 2015
 */

public class RealOverRelaxedSlice implements Sampler
{

    /**
     * The real variable being resampled.
     * Automatically filled in via reflection.
     */
    @SampledVariable WritableRealVar variable;
    
    /**
     * The factors connected to this variable.
     * Automatically filled in via reflection.
     */
    @ConnectedFactor List<LogScaleFactor> connectedFactors;
    
    public final double SLICE_SIZE = 2;
    public final int MAX_SLICE_SIZE = 5; // max size of slice is MAX_SLICE_SIZE * SLICE_SIZE
    
    @Override
    public void execute(Random rand)
    {
        double originalValue = variable.doubleValue();
        double originalLogUnnormalizedPotential = computeLogUnnormalizedPotentials(originalValue);
        double auxVariable = originalLogUnnormalizedPotential + Math.log(rand.nextDouble());
        Pair<Double, Double> interval = steppingOutInterval(rand, auxVariable, originalValue);
        double newValue = shrinkingSampling(auxVariable, originalValue, interval);
        variable.set(newValue);
    }

    private Pair<Double, Double> steppingOutInterval(Random rand, double auxVariable, double originalValue)
    {
        double L = originalValue - SLICE_SIZE * rand.nextDouble();
        double R = L + SLICE_SIZE; 
        int J = (int) Math.floor(MAX_SLICE_SIZE * rand.nextDouble());
        int K = (MAX_SLICE_SIZE - 1) - J; 
        
        double leftLogUnnormalizedPotential = computeLogUnnormalizedPotentials(L);
        double rightLogUnnormalizedPotential = computeLogUnnormalizedPotentials(R);
        
        while (J > 0 && (auxVariable < leftLogUnnormalizedPotential))
        {
            L -= SLICE_SIZE; 
            J -= 1; 
            leftLogUnnormalizedPotential = computeLogUnnormalizedPotentials(L);
        }

        while (K > 0 && (auxVariable < rightLogUnnormalizedPotential))
        {
            R += SLICE_SIZE; 
            K -= 1; 
            rightLogUnnormalizedPotential = computeLogUnnormalizedPotentials(R);
        }
        
        return new Pair<Double, Double>(L, R);
    }

    private double shrinkingSampling(double auxVariable, double originalValue, Pair<Double, Double> interval)
    {
        double L = interval.getFirst(); 
        double R = interval.getSecond();
        double w = SLICE_SIZE; 
        int a = MAX_SLICE_SIZE; 
        
        if (R - L < 1.1 * w)
        {
            while(true)
            {
                double M = (L + R) / 2;
                if (a == 0 || auxVariable < computeLogUnnormalizedPotentials(M))
                {
                    break;
                }
                if (originalValue > M)
                {
                    L = M; 
                }
                else
                {
                    R = M; 
                }
                a -= 1; 
                w *= 0.5;
            }
        }
        
        double Lhat = L; 
        double Rhat = R;
        
        while(a > 0)
        {
            a -= 1; 
            w *= 0.5;

            Lhat = (auxVariable >= computeLogUnnormalizedPotentials(Lhat + w)) ? Lhat + w : Lhat; 
            Rhat = (auxVariable >= computeLogUnnormalizedPotentials(Rhat - w)) ? Rhat - w : Rhat; 
        }
        
        double proposed = Lhat + Rhat - originalValue; 
        if (proposed < L || proposed > R || auxVariable >= computeLogUnnormalizedPotentials(proposed))
        {
            proposed = originalValue; 
        }
        
        return proposed; 
        
    }
    
    /**
     * Sets the variable to the given value, then compute the unnormalized
     * density of the relevant factors.
     * WARNING: should be used with care as it does not set back the original 
     * value.
     * @param value
     * @return
     */
    private double computeLogUnnormalizedPotentials(double value)
    {
      variable.set(value);
      double result = 0.0;
      for (LogScaleFactor f : connectedFactors)
        result += f.logDensity();
      return result;
    }

    @Override
    public String toString()
    {
      return "RealVariableOverRelaxedSlice [variable=" + variable + "]";
    }

    @Override
    public boolean setup() {
      return true;
    }
    
}

package blang.mcmc;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;


/**
 * An annotation used to specify where and how MCMC samplers 
 * can be applied in a probability models.
 * 
 * When writing a class implementing an MCMC move, two main 
 * annotations should be used. First, use SampledVariable to
 * specify the field that will hold a reference to the variable
 * to be resampled. Second, use ConnectedFactor to specify which
 * factors are expected to be connected to the variable.
 * 
 * The rules used to match up the fields of a sampler to the 
 * factors in a ProbabilityModel are implemented in 
 * blang.mcmc.Utils.
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 */
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.FIELD})
public @interface ConnectedFactor
{

}

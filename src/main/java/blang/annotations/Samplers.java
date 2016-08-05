package blang.annotations;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import blang.mcmc.Operator;



@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE})
public @interface Samplers
{
  public Class<? extends Operator>[] value();
}

package blang.accessibility;

import java.util.List;



public interface ExplorationRule
{
  /**
   * return null if the rule does not apply to this object, else, a list of constituents to recurse to 
   */
  public List<? extends ConstituentNode<?>> explore(Object object);
}
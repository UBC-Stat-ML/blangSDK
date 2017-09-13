package blang.runtime.objectgraph;

/**
 * A node (factor, variable, or component) in the accessibility graph.
 * 
 * Each such node is associated to a unique address in memory (i.e. an instance is essentially a pointer).
 * To be more precise, this association is established in one of two ways:
 * 
 * 1. a reference to an object o (with hashCode and equals based on o's identity instead of o's potentially overloaded hashCode and equal)
 * 2. a reference to a container c (e.g., an array, or List) as well as a key k (in this case, hashCode and equal are based on a 
 *    combination of the identity of c, and the standard hashCode and equal of k)
 *    
 * Case (1) is called an object node, and case (2) is called a constituent node. 
 * 
 * An important special case of a constituent node: the container c being a regular object, and the key k being a Field of c's class
 * 
 * Constituent nodes are needed for example to obtain slices of 
 * a matrix, partially observed arrays, etc. 
 * 
 * We assume all implementation provide appropriate hashCode and equal, in particular, by-passing custom hashCode and
 * equals of enclosed objects.
 * 
 * @author Alexandre Bouchard (alexandre.bouchard@gmail.com)
 *
 */
public interface Node
{
  public default String toStringSummary()
  {
    return toString();
  }
  public boolean isMutable();
}
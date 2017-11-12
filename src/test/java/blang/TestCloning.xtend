package blang

import blang.runtime.internals.objectgraph.AccessibilityGraph
import blang.runtime.internals.objectgraph.Node
import blang.runtime.internals.objectgraph.ObjectNode
import java.util.ArrayList
import java.util.Arrays
import java.util.LinkedHashSet
import java.util.List
import java.util.Set
import java.util.stream.Collectors
import org.junit.Assert
import org.junit.Test
import blang.runtime.internals.objectgraph.DeepCloner
import blang.runtime.internals.objectgraph.VariableUtils

class TestCloning {
  
  val List<Object> subjects = new ArrayList => [
    val examples = new Examples
    for (example : examples.all) {
      add(example.model)      
      add(example.sampledModel)
    }
    add(#[1,2,3,4])
    add(#[1,2,3,4].subList(1,3))
    add(Arrays.asList(1, 2))
  ]
  
  @Test def void cloningLibrary() {
    System.out.println("Cloning library - fast cloners disabled")
    testCloner[DeepCloner.deepClone(it)]
  }
  
  //  @Test def void existingKryoConfig() Does not pass the overlappingClasses check test
//  {
//    System.out.println("Existing Kryo config")
//    val Kryo kryo = new Kryo()
//    var DefaultInstantiatorStrategy defaultInstantiatorStrategy = new Kryo.DefaultInstantiatorStrategy()
//    defaultInstantiatorStrategy.setFallbackInstantiatorStrategy(new StdInstantiatorStrategy())
//    kryo.setInstantiatorStrategy(defaultInstantiatorStrategy)
//    kryo.getFieldSerializerConfig().setCopyTransient(false)
//    testCloner[kryo.copy(it)]
//  }
//
//  @Test def void stdInstantiatorKryo() { has a bunch of problems
//    System.out.println("StdInstantiator Kryo config")
//    val Kryo kryo = new Kryo()
//    kryo.setInstantiatorStrategy(new StdInstantiatorStrategy())
//    kryo.getFieldSerializerConfig().setCopyTransient(false)
//    testCloner[kryo.copy(it)]
//  }

  @FunctionalInterface private static interface Cloner {
    def Object clone(Object o)
  }

  def void testCloner(blang.TestCloning.Cloner cloner) {
    var boolean error = false;
    for (Object o : subjects) {
      println('''Attempting «o.getClass().getSimpleName()»''')
      try {
        var Object cloned = cloner.clone(o)
        if(o !== null && cloned === null) throw new RuntimeException("Shouldn't be null");
        
        val overlapClasses = overlappingClasses(o, cloned)
        println('''   overlap: «overlapClasses.map[simpleName]»''')
        check(overlapClasses)
        
        println('''   OK: "«o.toString()»" cloned to "«cloned.toString()»"''')
      } catch(Throwable e) {
        println('''   ERROR: «e.class.simpleName»''') 
        error = true
      }
    }
    println
    Assert.assertTrue(!error)
  }
  
  def check(Set<Class<?>> classes) {
    for (aClass : classes) {
      if (VariableUtils::isVariable(aClass))
        throw new RuntimeException('''A variable found in the overlap: «aClass.simpleName»''')
    }
  }
  
  def private Set<Class<?>> overlappingClasses(Object o1, Object o2) {
    val overlap = nodes(o1)
    overlap.retainAll(nodes(o2))
    val Set<Class<?>> result = new LinkedHashSet
    for (o : overlap) {
      if (o instanceof ObjectNode<?>)
      result.add((o as ObjectNode<?>).object.class)
    }
    return result
  }
  
  def private Set<Node> nodes(Object o) {
    val AccessibilityGraph ag = new AccessibilityGraph
    ag.add(o)
    return ag.accessibleNodes.collect(Collectors::toSet)
  }
}

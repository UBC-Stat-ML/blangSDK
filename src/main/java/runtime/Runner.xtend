package runtime

import blang.annotations.DeboxedName
import blang.core.Model
import blang.core.Sampler
import briefj.opt.Option
import briefj.run.Mains
import com.google.common.base.Optional
import com.google.common.base.Splitter
import java.lang.reflect.Constructor
import java.lang.reflect.Parameter
import java.util.ArrayList
import java.util.Collections
import java.util.List
import java.util.Map
import java.util.Random
import utils.StaticUtils
import blang.annotations.Param
import java.lang.reflect.ParameterizedType
import java.util.function.Supplier
import java.lang.reflect.Type

class Runner implements Runnable {
  
  @Option 
  var public String inputs
  
  @Option 
  var public Random random = new Random(1)
  
  @Option 
  var public int nIterations = 10_000_000
  
  val Class<? extends Model> modelType
   
  new(Class<? extends Model> modelType) {
    this.modelType = modelType
  }
  
  def private Model instantiateModel() {
    // Parse command line arguments for inputs
    val Map<String, String> parsedInputs = parseInputs(inputs)
    
    // Find constructor
    val Constructor<?> constructor = StaticUtils.pickUnique(modelType.constructors)
    
    // Build argument lists
    val List<Object> arguments = new ArrayList
    val Type [] argumentsWithGenerics = constructor.genericParameterTypes
    val Parameter [] parameters = constructor.parameters
    for (var int i = 0; i < parameters.size(); i++) {
      val Parameter constructorArg = parameters.get(i)
      // Find deboxed name
      val DeboxedName deboxedName = StaticUtils::pickUnique(constructorArg.getAnnotationsByType(DeboxedName))
      val String key = deboxedName.value()
      
      val boolean isParam = !constructorArg.getAnnotationsByType(Param).isEmpty()
      
      // Find an implementation, i.e. use @DefaultImplementation if constr.type is an interface 
      
      val Class<?> argumentType = getImplementation(constructorArg.type, argumentsWithGenerics.get(i), isParam)
      
      // See if a command line argument was provided
      val String commandLineArg = parsedInputs.get(key)   // TODO: check spaces get trimmed
      
      val Object instantiatedArgument = if (commandLineArg === null) {
        instantiateConstructorArgument(argumentType) 
      } else {
        instantiateConstructorArgument(argumentType, commandLineArg)        
      }
      
      // Do boxing if it's a param
      val Object instantiatedBoxedArgument = if (isParam) {
        new ConstantSupplier(instantiatedArgument)
      } else {
        instantiatedArgument
      }
      
      arguments.add(instantiatedBoxedArgument)
    }
    val Object [] argumentsVarArg = arguments
    return constructor.newInstance(argumentsVarArg) as Model
  }
  
  def static private Map<String, String> parseInputs(String inputs) {
    return Splitter.on(",").withKeyValueSeparator("=").split(inputs)
  }
  
  def static Object instantiateConstructorArgument(Class<?> type) {
    return type.getConstructor().newInstance() 
  }
  
  def static Object instantiateConstructorArgument(Class<?> type, String commandLineArgument) {
    return type.getConstructor(String).newInstance(commandLineArgument)
  }
  
  def static private Class<?> getImplementation(Class<?> boxedType, Type boxedTypeWithGenerics, boolean isParam) {
    val Class<?> deboxedType = {
      if (isParam) {
        StaticUtils::pickUnique((boxedTypeWithGenerics as ParameterizedType).actualTypeArguments) as Class<?>
//        // find the Supplier 
//        val ParameterizedType supplierInterfaceSpec = StaticUtils::pickUnique(boxedTypeWithGenerics.class.genericInterfaces.filter(ParameterizedType).filter[it.rawType == Supplier])
//        StaticUtils::pickUnique(supplierInterfaceSpec.actualTypeArguments) as Class<?>
      } else {
        boxedType
      }
    }
    if (deboxedType.isInterface()) {
      // use type annotation @DefaultImplementation if it's an interface
      val DefaultImplementation defaultImplAnn = StaticUtils::pickUnique(deboxedType.getAnnotationsByType(DefaultImplementation))
      return defaultImplAnn.value()
    } else {
      return deboxedType
    }
  }
  
  def public static void main(String [] args) {
    var Optional<Class<? extends Model>> theClass = Optional.absent() 
    if (!args.isEmpty()) try {
      theClass = Optional.of((Class.forName(args.get(0)) as Class<? extends Model>)) 
    } catch (ClassNotFoundException e) {}

    if (theClass.isPresent()) {
      Mains.instrumentedRun(args.subList(1, args.size()).toArray(newArrayOfSize(0)), new Runner(theClass.get()))  
    } else {
      System.err.println('''The first argument must specify a fully qualified (e.g. package.subpack.ClassName) class implementing the Model interface.''') 
      System.exit(1) 
    }
  }
  
  override void run() {
    var List<Sampler> samplers = ModelUtils.samplers(instantiateModel()) 
    for (var int i=0; i < nIterations; i++) {
      Collections.shuffle(samplers, random) 
      for (Sampler s : samplers) s.execute(random) 
      if ((i + 1) % 1_000_000 === 0) 
        System.out.println('''Iteration «(i + 1)»''') 
    }
  }
  
}

// blang my.Model -nIter 1000 -inputs observations = csv data.csv; hyperPrior = 45
// blang my.Model -nIter 1000 -inputs observations = generate 10 datapoints, 3 dimensions; hyperPrior = 45
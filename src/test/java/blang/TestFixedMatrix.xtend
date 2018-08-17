package blang

import org.junit.Test
import blang.validation.internals.fixtures.FixedMatrix
import blang.mcmc.internals.SamplerBuilder
import blang.runtime.internals.objectgraph.GraphAnalysis
import org.junit.Assert
import xlinear.MatrixOperations
import blang.types.StaticUtils

class TestFixedMatrix {
  
  
  @Test
  def void testFixed() {
    val model = new FixedMatrix.Builder().build
    val built = SamplerBuilder::build(new GraphAnalysis(model))
    Assert::assertTrue(built.list.empty) 
  }
  
  @Test
  def void testMutable() {
    val model = new FixedMatrix.Builder().setM(MatrixOperations::dense(2)).build
    val built = SamplerBuilder::build(new GraphAnalysis(model))
    Assert::assertTrue(!built.list.empty) 
  } 
  
  @Test
  def void testRecurse() {
    val simplex = StaticUtils::fixedSimplex(0.5, 0.5)
    val model = new FixedMatrix.Builder().setM(simplex.row(0)).build
    val built = SamplerBuilder::build(new GraphAnalysis(model))
    Assert::assertTrue(built.list.empty) 
  }
}
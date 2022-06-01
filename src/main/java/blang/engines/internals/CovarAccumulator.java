package blang.engines.internals;

public class CovarAccumulator
{
  double meanx = 0, meany = 0, C = 0;
  int n = 0;
  public void add(double x, double y) {
    n += 1;
    double dx = x - meanx;
    meanx += dx / n;
    meany += (y - meany) / n;
    C += dx * (y - meany);
  }
  public double sampleCovariance() {
    return C / n;
  }
}

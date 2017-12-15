package blang.types.internals;

public class InvalidParameter extends RuntimeException 
{
  private static final long serialVersionUID = 1L;
  
  public static final InvalidParameter instance = new InvalidParameter();

  private InvalidParameter() 
  {
    super("Invalid parameter. Assigned Double.NEGATIVE_INFINITY to that factor.");
  }

  @Override
  public synchronized Throwable fillInStackTrace() 
  {
    return this;
  }
}

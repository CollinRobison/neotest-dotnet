using Xunit;

namespace Maintenance.Xunit;

public class Tests
{
    [Fact]
    public void Passes()
    {
        Console.WriteLine("xUnit standard output");
        Assert.True(true);
    }

    [Fact]
    public void Fails()
    {
        Console.Error.WriteLine("xUnit standard error");
        Assert.Fail("expected failure");
    }

    [Fact(Skip = "maintenance fixture skip")]
    public void Skips()
    {
    }
}

using Xunit;

namespace DotnetFixtures.XUnit;

public class ResultTests
{
    [Fact]
    public void Passing() => Assert.Equal(4, 2 + 2);

    [Fact]
    public void Failing() => Assert.Fail("intentional xUnit integration failure");

    [Fact(Skip = "intentional xUnit integration skip")]
    public void Skipped() { }
}

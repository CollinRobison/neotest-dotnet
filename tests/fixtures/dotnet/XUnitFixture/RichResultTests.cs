using System;
using Xunit;

namespace DotnetFixtures.XUnit;

public class RichResultTests
{
    [Fact(DisplayName = "display: café / punctuation!")]
    public void CustomDisplayName() => Assert.True(true);

    [Fact]
    public void ExceptionWithOutput()
    {
        Console.WriteLine("stdout sentinel");
        Console.Error.WriteLine("stderr sentinel");
        throw new InvalidOperationException("exception sentinel");
    }

    [Theory]
    [InlineData(1, true)]
    [InlineData(2, false)]
    public void Parameterized(int value, bool expected) => Assert.Equal(expected, value == 1);
}

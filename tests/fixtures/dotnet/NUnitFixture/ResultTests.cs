using NUnit.Framework;

namespace DotnetFixtures.NUnit;

public class ResultTests
{
    [Test]
    public void Passing() => Assert.That(2 + 2, Is.EqualTo(4));

    [Test]
    public void Failing() => Assert.Fail("intentional NUnit integration failure");

    [Test]
    [Ignore("intentional NUnit integration skip")]
    public void Skipped() { }

    [Theory]
    [TestCase(1)]
    [TestCase(2)]
    public void TheoryCases(int value) => Assert.That(value, Is.GreaterThan(0));
}

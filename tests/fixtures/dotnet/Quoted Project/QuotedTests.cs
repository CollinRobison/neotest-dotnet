using NUnit.Framework;

namespace DotnetFixtures.QuotedProject;

public class QuotedTests
{
    [Test]
    public void Passing() => Assert.That(1, Is.EqualTo(1));

    [TestCase(1)]
    [TestCase(2)]
    public void PassingParameterized(int value) => Assert.That(value, Is.GreaterThan(0));
}

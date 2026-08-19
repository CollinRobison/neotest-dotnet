using NUnit.Framework;

namespace DotnetFixtures.QuotedProject;

public class QuotedTests
{
    [Test]
    public void Passing() => Assert.That(1, Is.EqualTo(1));
}

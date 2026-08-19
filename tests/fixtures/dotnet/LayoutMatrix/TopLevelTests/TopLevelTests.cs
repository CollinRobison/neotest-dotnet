using NUnit.Framework;

namespace DotnetFixtures.LayoutMatrix.TopLevel;

public class TopLevelTests
{
    [Test]
    public void Passing() => Assert.That(2 + 2, Is.EqualTo(4));
}

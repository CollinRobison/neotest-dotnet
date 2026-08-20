using NUnit.Framework;

namespace DotnetFixtures.LayoutMatrix.Nested;

public class NestedTests
{
    [Test]
    public void Passing() => Assert.That("nested", Is.Not.Empty);
}

using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DotnetFixtures.MSTest;

[TestClass]
public class ResultTests
{
    [TestMethod]
    public void Passing() => Assert.AreEqual(4, 2 + 2);

    [TestMethod]
    public void Failing() => Assert.Fail("intentional MSTest integration failure");

    [TestMethod]
    [Ignore("intentional MSTest integration skip")]
    public void Skipped() { }
}

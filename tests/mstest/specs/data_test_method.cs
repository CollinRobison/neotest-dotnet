using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Fixtures;

[TestClass]
public class DataTests
{
    [DataTestMethod]
    [DataRow(1)]
    [DataRow(2)]
    public void Adds(int value)
    {
        Assert.IsTrue(value > 0);
    }

    [TestMethod]
    public void Smoke()
    {
        Assert.IsTrue(true);
    }
}

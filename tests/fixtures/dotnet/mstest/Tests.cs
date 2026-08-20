using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Maintenance.MSTest;

[TestClass]
public class Tests
{
    [TestMethod]
    public void Passes()
    {
        Console.WriteLine("MSTest standard output");
        Assert.IsTrue(true);
    }

    [TestMethod]
    public void Fails()
    {
        Console.Error.WriteLine("MSTest standard error");
        Assert.Fail("expected failure");
    }

    [TestMethod]
    [Ignore("maintenance fixture skip")]
    public void Skips()
    {
    }
}

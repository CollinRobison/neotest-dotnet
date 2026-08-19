using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Fixtures;

public sealed class CustomTestMethodAttribute : TestMethodAttribute
{
}

[TestClass]
public class CustomTests
{
    [CustomTestMethod]
    public void CustomTest()
    {
        Assert.IsTrue(true);
    }
}

using NUnit.Framework;

namespace Maintenance.NUnit;

public class Tests
{
    [Test]
    public void Passes()
    {
        TestContext.Out.WriteLine("NUnit standard output");
        Assert.That(true, Is.True);
    }

    [Test]
    public void Fails()
    {
        TestContext.Error.WriteLine("NUnit standard error");
        Assert.Fail("expected failure");
    }

    [Test]
    [Ignore("maintenance fixture skip")]
    public void Skips()
    {
    }
}

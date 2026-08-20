using NUnit.Framework;

public class MixedAttributes
{
    [Test]
    [TestCase(1)]
    [TestCase(2)]
    public void Mixed(int value)
    {
        Assert.That(value, Is.GreaterThan(0));
    }
}

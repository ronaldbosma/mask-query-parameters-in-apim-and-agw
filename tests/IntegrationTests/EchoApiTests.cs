using IntegrationTests.Clients;
using IntegrationTests.Configuration;
using System.Net;

namespace IntegrationTests;

/// <summary>
/// Tests scenarios for a valid authorized client and invalid unauthorized client.
/// </summary>
[TestClass]
public sealed class EchoApiTests
{
    [TestMethod]
    public async Task Call_Echo_API_Directly_On_API_Management_With_Subscription_Key_In_Query_Parameter()
    {
        // Arrange
        var config = TestConfiguration.Load();

        // Get subscription key from Key Vault
        var keyVaultClient = new KeyVaultClient(config.AzureKeyVaultUri);
        var subscriptionKey = await keyVaultClient.GetSecretValueAsync("apim-master-subscription-key");

        var client = new IntegrationTestHttpClient(config.AzureApiManagementGatewayUrl);

        // Act
        var response = await client.GetAsync($"echo?subscription-key={subscriptionKey}&foo=bar");

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode, "Unexpected status code returned");
    }
}

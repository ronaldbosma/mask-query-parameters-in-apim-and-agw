# Mask query parameters in Azure API Management and Application Gateway

> [!IMPORTANT]  
> This template is under construction and not yet fully functional.


## Getting Started

### Prerequisites  

Before you can deploy this template, make sure you have the following tools installed and the necessary permissions:  

- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)  
  - Installing `azd` also installs the following tools:  
    - [GitHub CLI](https://cli.github.com)  
    - [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)  
- [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) 
  _(This template uses a predown hook to permanently delete the log analytics workspace to prevent issues with future deployments.)_
- You need Owner or Contributor permissions on an Azure Subscription to deploy this template.  

### Deployment

Once the prerequisites are installed on your machine, you can deploy this template using the following steps:

1. Run the `azd init` command in an empty directory with the `--template` parameter to clone this template into the current directory.  

    ```cmd
    azd init --template ronaldbosma/mask-query-parameters-in-apim-and-agw
    ```

    When prompted, specify the name of the environment, for example, `maskqueryparams`. The maximum length is 32 characters.

1. Run the `azd auth login` command to authenticate to your Azure subscription _(if you haven't already)_.

    ```cmd
    azd auth login
    ```

1. Run the `azd up` command to provision the resources in your Azure subscription. 

    ```cmd
    azd up
    ```

    See [Troubleshooting](#troubleshooting) if you encounter any issues during deployment.

1. Once the deployment is complete, you can locally modify the application or infrastructure and run `azd up` again to update the resources in Azure.

### Test

The [tests.http](./tests/tests.http) file contains a set of HTTP requests that you can use to test the deployed resources. 

Follow these steps to test the sample application using Visual Studio Code:

1. Install the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension in Visual Studio Code. 
1. The API is protected and needs to be called with a subscription key. Locate the `Built-in all-access` subscription in API Management and copy the primary key.
1. Add an environment to your Visual Studio Code user settings with the Application Gateway public IP address, API Management hostname and subscription key. Use the following example and replace the values with your own:
   ```
   "rest-client.environmentVariables": {
       "maskqueryparam": {
           "agwIPAddress": "123.456.78.90",
           "apimHostname": "apim-maskqueryparams-nwe-kt2tx.azure-api.net",
           "apimSubscriptionKey": "1234567890abcdefghijklmnopqrstuv"
       }
   }
   ```
1. Open `tests.http` and at the bottom right of the editor, select the `maskqueryparam` environment you just configured.
1. Click on `Send Request` above the requests. This will call the Echo API with the subscription key as a query parameter.
1. Open Application Insights in the Azure portal and select `Logs` in the left menu.
1. Execute the following kusto query to retrieved logged API Management requests. 
   It might take a few minutes before the first requests are logged.

    ```kusto
    requests
    | where customDimensions["Service Type"] == "API Management"
    | extend subscription = tostring(customDimensions["Subscription Name"])
    | project timestamp, subscription, url
    | sort by timestamp desc
    ```

### Clean up

Once you're done and want to clean up, run the `azd down` command. By including the `--purge` parameter, you ensure that the API Management service doesn't remain in a soft-deleted state, which could block future deployments of the same environment.

```cmd
azd down --purge
```


## Troubleshooting

### API Management deployment failed because the service already exists in soft-deleted state

If you've previously deployed this template and deleted the resources, you may encounter the following error when redeploying the template. This error occurs because the API Management service is in a soft-deleted state and needs to be purged before you can create a new service with the same name.

```json
{
    "code": "DeploymentFailed",
    "target": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-maskqueryparams-nwe-kt2tx/providers/Microsoft.Resources/deployments/apiManagement",
    "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/arm-deployment-operations for usage details.",
    "details": [
        {
            "code": "ServiceAlreadyExistsInSoftDeletedState",
            "message": "Api service apim-maskqueryparams-nwe-kt2tx was soft-deleted. In order to create the new service with the same name, you have to either undelete the service or purge it. See https://aka.ms/apimsoftdelete."
        }
    ]
}
```

Use the [az apim deletedservice list](https://learn.microsoft.com/en-us/cli/azure/apim/deletedservice?view=azure-cli-latest#az-apim-deletedservice-list) Azure CLI command to list all deleted API Management services in your subscription. Locate the service that is in a soft-deleted state and purge it using the [purge](https://learn.microsoft.com/en-us/cli/azure/apim/deletedservice?view=azure-cli-latest#az-apim-deletedservice-purge) command. See the following example:

```cmd
az apim deletedservice purge --location "norwayeast" --service-name "apim-maskqueryparams-nwe-kt2tx"
```
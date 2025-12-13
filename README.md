# Mask query parameters in Azure API Management and Application Gateway

Deploys an Azure API Management service and an Application Gateway with a Web Application Firewall (WAF) to show how to mask query parameters in logging.
A Key Vault is also included to securely store client secrets for integration tests.

Relevant logs:
- **Application Gateway - Access Log**: IMPORTANT: The subscription key is logged in the Application Gateway Access Log and I haven't found a way to mask it.
- **Application Gateway - Firewall Log**: See the `logScrubbing` setting of the resource `wafPolicy` in [application-gateway.bicep](infra/modules/services/application-gateway.bicep) for how to mask the `subscription-key` query parameter in the Application Gateway Firewall Log.
- **API Management - Requests**: See the `dataMasking` settings of the `apimInsightsDiagnostics` resource in [api-management.bicep](infra/modules/services/api-management.bicep) for how to mask the `subscription-key` query parameter in the request logs.
- **API Management - Gateway Log**: No query parameters are logged in the gateway log. So, no masking is required.

  By default, a Consumption tier API Management instance is deployed to reduce cost. 
  This tier doesn't support logging to the API Management Gateway Log, even though you can deploy the diagnostics settings.
  If you want to have the API Management Gateway Log, deploy a different tier:
  - Open the [main.bicep](infra/main.bicep).
  - Locate the `apiManagementSettings` variable.
  - Set the `sku` to e.g. `BasicV2`.  
    If you use a V2 tier, make sure that you select a [supported region](https://learn.microsoft.com/en-us/azure/api-management/api-management-region-availability) during deployment.

> [!IMPORTANT]  
> This template is not production-ready; it uses minimal cost SKUs and omits network isolation, advanced security, governance and resiliency. Harden security, implement enterprise controls and/or replace modules with [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/) before any production use.


## Getting Started

### Prerequisites  

Before you can deploy this template, make sure you have the following tools installed and the necessary permissions:  

- [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)  
  - Installing `azd` also installs the following tools:  
    - [GitHub CLI](https://cli.github.com)  
    - [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)  

#### Optional Prerequisites

This templates uses a hook to permanently delete the Log Analytics Workspace. If you do not have the following tools installed, remove the hook from [azure.yaml](azure.yaml). See [this section](#hooks) for more information.

- [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

### Deployment

Once the prerequisites are installed on your machine, you can deploy this template using the following steps:

1. Run the `azd init` command in an empty directory with the `--template` parameter to clone this template into the current directory.  

    ```cmd
    azd init --template ronaldbosma/mask-query-parameters-in-apim-and-agw
    ```

    When prompted, specify the name of the environment, for example, `maskqueryparams`. The maximum length is 32 characters.

1. Run the `azd auth login` command to authenticate to your Azure subscription using the **Azure Developer CLI** _(if you haven't already)_.

    ```cmd
    azd auth login
    ```

1. Run the `az login` command to authenticate to your Azure subscription using the **Azure CLI** _(if you haven't already)_. This is required for the [hooks](#hooks) to function properly. Make sure to log into the same tenant as the Azure Developer CLI.

    ```cmd
    az login
    ```

1. Run the `azd up` command to provision the resources in your Azure subscription. 

    ```cmd
    azd up
    ```

    See [Troubleshooting](#troubleshooting) if you encounter any issues during deployment.

1. Once the deployment is complete, you can locally modify the application or infrastructure and run `azd up` again to update the resources in Azure.

### Demo

See the [Demo Guide](demos/demo-query-param-masking.md) for a step-by-step walkthrough on how to check and demonstrate the masking of query parameters.

### Clean up

Once you're done and want to clean up, run the `azd down` command. By including the `--purge` parameter, you ensure that the API Management service doesn't remain in a soft-deleted state, which could block future deployments of the same environment.

```cmd
azd down --purge
```


## Contents

The repository consists of the following files and directories:

```
├── demos                      [ Demo guide(s) ]
├── hooks                      [ AZD hooks ]
├── images                     [ Images used in the README ]
├── infra                      [ Infrastructure As Code files ]
│   ├── functions              [ Bicep user-defined functions ]
│   ├── modules                
│   │   ├── application        [ Modules for application infrastructure resources ]
│   │   └── services           [ Modules for all Azure services ]
│   ├── types                  [ Bicep user-defined types ]
│   ├── main.bicep             [ Main infrastructure file ]
│   └── main.parameters.json   [ Parameters file ]
├── tests                      [ Test files and scripts ]
├── azure.yaml                 [ Describes the apps and types of Azure resources ]
└── bicepconfig.json           [ Bicep configuration file ]
```


## Hooks

This template has hooks that are executed at different stages of the deployment process. The following hooks are included:
  
- [predown-remove-law.ps1](hooks/predown-remove-law.ps1): 
  This PowerShell script is executed before the resources are removed. 
  It permanently deletes the Log Analytics workspace to prevent issues with future deployments. 
  Sometimes the requests and traces don't show up in Application Insights & Log Analytics when removing and deploying the template multiple times.


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

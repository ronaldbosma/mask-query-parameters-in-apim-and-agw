//=============================================================================
// Mask query parameters in Azure API Management and Application Gateway
// Source: https://github.com/ronaldbosma/mask-query-parameters-in-apim-and-agw
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, getInstanceId } from './functions/naming-conventions.bicep'

//=============================================================================
// Parameters
//=============================================================================

@minLength(1)
@description('Location to use for all resources')
param location string

@minLength(1)
@maxLength(32)
@description('The name of the environment to deploy to')
param environmentName string

@maxLength(5) // The maximum length of the storage account name and key vault name is 24 characters. To prevent errors the instance name should be short.
@description('The instance that will be added to the deployed resources names to make them unique. Will be generated if not provided.')
param instance string = ''

//=============================================================================
// Variables
//=============================================================================

// Determine the instance id based on the provided instance or by generating a new one
var instanceId = getInstanceId(environmentName, location, instance)

var resourceGroupName = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  sku: 'Consumption'
  publisherName: 'admin@example.org'
  publisherEmail: 'admin@example.org'
}

var appInsightsSettings = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var applicationGatewaySettings = {
  applicationGatewayName: getResourceName('applicationGateway', environmentName, location, instanceId)
  publicIpAddressName: getResourceName('publicIpAddress', environmentName, location, instanceId)
  wafPolicyName: getResourceName('webApplicationFirewallPolicy', environmentName, location, instanceId)
}

var keyVaultName string = getResourceName('keyVault', environmentName, location, instanceId)

var virtualNetworkSettings = {
  virtualNetworkName: getResourceName('virtualNetwork', environmentName, location, instanceId)
  applicationGatewaySubnetName: getResourceName('subnet', environmentName, location, 'agw-${instanceId}')
}

var tags = {
  'azd-env-name': environmentName
  'azd-template': 'ronaldbosma/mask-query-parameters-in-apim-and-agw'
}

//=============================================================================
// Resources
//=============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module appInsights 'modules/services/app-insights.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module virtualNetwork 'modules/services/virtual-network.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    virtualNetworkSettings: virtualNetworkSettings
  }
}

module apiManagement 'modules/services/api-management.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsSettings: appInsightsSettings
    keyVaultName: keyVaultName
  }
  dependsOn: [
    appInsights
  ]
}

module appGateway './modules/services/application-gateway.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    applicationGatewaySettings: applicationGatewaySettings
    subnetId: virtualNetwork.outputs.agwSubnetId
    apiManagementServiceName: apiManagementSettings.serviceName
    appInsightsSettings: appInsightsSettings
  }
}

module keyVault 'modules/services/key-vault.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}

module assignRolesToDeployer 'modules/shared/assign-roles-to-principal.bicep' = {
  scope: resourceGroup
  params: {
    principalId: deployer().objectId
    isAdmin: true
    keyVaultName: keyVaultName
  }
  dependsOn: [
    keyVault
  ]
}


//=============================================================================
// Application Resources
//=============================================================================

module echoApi 'modules/application/echo-api.bicep' = {
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagementSettings.serviceName
  }
  dependsOn: [
    apiManagement
  ]
}


//=============================================================================
// Outputs
//=============================================================================

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_GATEWAY_NAME string = applicationGatewaySettings.applicationGatewayName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_RESOURCE_GROUP string = resourceGroupName

// Return resource endpoints
output AZURE_API_MANAGEMENT_GATEWAY_URL string = apiManagement.outputs.gatewayUrl
output AZURE_KEY_VAULT_URI string = keyVault.outputs.vaultUri
output AZURE_APPLICATION_GATEWAY_PUBLIC_IP_ADDRESS string = appGateway.outputs.publicIpAddress

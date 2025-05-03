//=============================================================================
// Mask query parameters in Azure API Management and Application Gateway
// Source: https://github.com/ronaldbosma/mask-query-parameters-in-apim-and-agw
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, getInstanceId } from './functions/naming-conventions.bicep'
import * as settings from './types/settings.bicep'


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
}

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

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module appInsights 'modules/services/app-insights.bicep' = {
  name: 'appInsights'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module virtualNetwork 'modules/services/virtual-network.bicep' = {
  name: 'virtualNetwork'
  scope: resourceGroup
  params: {
    virtualNetworkSettings: virtualNetworkSettings
    location: location
  }
}

module apiManagement 'modules/services/api-management.bicep' = {
  name: 'apiManagement'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
  }
  dependsOn: [
    appInsights
  ]
}

module appGateway './modules/services/application-gateway.bicep' = {
  name: 'appGateway'
  scope: resourceGroup
  params: {
    applicationGatewaySettings: applicationGatewaySettings
    location: location
    subnetId: virtualNetwork.outputs.agwSubnetId
    apiManagementServiceName: apiManagementSettings.serviceName
  }
}


//=============================================================================
// Application Resources
//=============================================================================

module echoApi 'modules/application/echo-api.bicep' = {
  name: 'echoApi'
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
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_RESOURCE_GROUP string = resourceGroupName

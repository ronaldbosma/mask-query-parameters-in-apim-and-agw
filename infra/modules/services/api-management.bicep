//=============================================================================
// API Management
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { apiManagementSettingsType, appInsightsSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags object

@description('The settings for the API Management Service that will be created')
param apiManagementSettings apiManagementSettingsType

@description('The settings for App Insights')
param appInsightsSettings appInsightsSettingsType

//=============================================================================
// Variables
//=============================================================================

var serviceTags = union(tags, {
  'azd-service-name': 'apim'
})

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsSettings.appInsightsName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: appInsightsSettings.logAnalyticsWorkspaceName
}

//=============================================================================
// Resources
//=============================================================================

// API Management - Consumption tier (see also: https://learn.microsoft.com/en-us/azure/api-management/quickstart-bicep?tabs=CLI)

resource apiManagementService 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: apiManagementSettings.serviceName
  location: location
  tags: serviceTags
  sku: {
    name: apiManagementSettings.sku
    capacity: apiManagementSettings.sku == 'Consumption' ? 0 : 1
  }
  properties: {
    publisherName: apiManagementSettings.publisherName
    publisherEmail: apiManagementSettings.publisherEmail
  }
  identity: {
    type: 'SystemAssigned'
  }
}


// Store the app insights connection string in a named value

resource appInsightsConnectionStringNamedValue 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'appinsights-connection-string'
  parent: apiManagementService
  properties: {
    displayName: 'appinsights-connection-string'
    value: appInsights.properties.ConnectionString
  }
}


// Configure API Management to log to App Insights
// - we need a logger that is connected to the App Insights instance
// - we need diagnostics settings that specify what to log to the logger

resource apimAppInsightsLogger 'Microsoft.ApiManagement/service/loggers@2024-06-01-preview' = {
  name: appInsightsSettings.appInsightsName
  parent: apiManagementService
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      // If we would reference the connection string directly using appInsights.properties.ConnectionString,
      // a new named value is created every time we execute a deployment
      connectionString: '{{${appInsightsConnectionStringNamedValue.properties.displayName}}}'
    }
    resourceId: appInsights.id
  }
}

resource apimInsightsDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2024-06-01-preview' = {
  name: 'applicationinsights' // The name of the diagnostics resource has to be applicationinsights, because that's the logger type we chose
  parent: apiManagementService
  properties: {
    alwaysLog: 'allErrors'
    loggerId: apimAppInsightsLogger.id
    httpCorrelationProtocol: 'W3C' // Enable logging to app insights in W3C format
    frontend: {
      request: {
        dataMasking: {
          queryParams: [
            {
              value: 'subscription-key' // Use * to mask or hide all query parameters
              mode: 'Mask'              // Valid modes are: Hide and Mask
            }
          ]
        }
      }
    }
    backend: {
      request: {
        dataMasking: {
          queryParams: [
            {
              value: 'subscription-key' // Use * to mask or hide all query parameters
              mode: 'Mask'              // Valid modes are: Hide and Mask
            }
          ]
        }
      }
    }
  }
}


// Diagnostics settings for API Management
// Thse can be deployed for a Conspumption tier, but don't actualy do anything for this tier

resource apimDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${apiManagementSettings.serviceName}-diag'
  scope: apiManagementService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'AllLogs'
        enabled: true
      }
      {
        categoryGroup: 'Audit'
        enabled: true
      }
    ]
  }
}

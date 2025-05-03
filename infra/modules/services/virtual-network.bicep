//=============================================================================
// Virtual Network
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { virtualNetworkSettingsType } from '../../types/settings.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The settings for the virtual network')
param virtualNetworkSettings virtualNetworkSettingsType

@description('Location to use for all resources')
param location string

//=============================================================================
// Resources
//=============================================================================


// Network Security Group for API Management subnet
resource apimNSG 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: virtualNetworkSettings.apiManagementNSGName
  location: location
  properties: {
    securityRules: [
      // SKIPPED: Inbound	Internet	*	VirtualNetwork	[80], 443	TCP	Allow	Client communication to API Management	External only
      {
        name: 'management-endpoint-for-azure-portal-and-powershell'
        properties: {
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          direction: 'Inbound'
          protocol: 'TCP'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          priority: 110
        }
      }
      {
        name: 'azure-infrastructure-load-balancer'
        properties: {
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '6390'
          direction: 'Inbound'
          protocol: 'TCP'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          priority: 120
        }
      }
      // SKIPPED: Inbound	AzureTrafficManager	*	VirtualNetwork	443	TCP	Allow	Azure Traffic Manager routing for multi-region deployment	External only
      {
        name: 'dependency-on-azure-storage'
        properties: {
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '443'
          direction: 'Outbound'
          protocol: 'TCP'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          priority: 140
        }
      }
      {
        name: 'access-to-azure-sql-endpoints'
        properties: {
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          direction: 'Outbound'
          protocol: 'TCP'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          priority: 150
        }
      }
      {
        name: 'access-to-azure-key-vault'
        properties: {
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '443'
          direction: 'Outbound'
          protocol: 'TCP'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
          priority: 160
        }
      }
      {
        name: 'publish-diagnostics-logs-and-metrics-resource-health-and-application-insights'
        properties: {
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '443'
          direction: 'Outbound'
          protocol: 'TCP'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          priority: 170
        }
      }
    ]
  }
}


// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: virtualNetworkSettings.virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: virtualNetworkSettings.applicationGatewaySubnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: virtualNetworkSettings.apiManagementSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: apimNSG.id
          }
        }
      }
    ]
  }

  resource agwSubnet 'subnets' existing = {
    name: virtualNetworkSettings.applicationGatewaySubnetName
  }

  resource apimSubnet 'subnets' existing = {
    name: virtualNetworkSettings.apiManagementSubnetName
  }
}


//=============================================================================
// Outputs
//=============================================================================

output agwSubnetId string = virtualNetwork::agwSubnet.id
output apimSubnetId string = virtualNetwork::apimSubnet.id

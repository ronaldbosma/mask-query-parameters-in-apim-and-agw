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
    ]
  }

  resource agwSubnet 'subnets' existing = {
    name: virtualNetworkSettings.applicationGatewaySubnetName
  }
}


//=============================================================================
// Outputs
//=============================================================================

output agwSubnetId string = virtualNetwork::agwSubnet.id

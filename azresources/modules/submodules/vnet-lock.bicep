targetScope = 'resourceGroup'

@description('Name of the VNet to lock')
param vnetName string

@description('Lock configuration')
param lock object

// Existing VNet reference
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

// Resource Lock for VNet
resource vnetLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: lock.name
  scope: vnet
  properties: {
    level: lock.kind
    notes: 'Created by Bicep deployment.'
  }
}

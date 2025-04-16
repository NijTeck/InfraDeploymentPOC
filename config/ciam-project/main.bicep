@description('The location for all resources')
param location string = 'centralus'

@description('The environment name')
param environment string = 'tst'

@description('The subscription ID')
param subscriptionId string

@description('The resource group name')
param resourceGroupName string

@description('The virtual network ID')
param virtualNetworkId string

@description('The private DNS zone IDs')
param privateDnsZones object

@description('The storage container path for vulnerability assessments')
@secure()
param vulnerabilityAssessmentsStorageContainerPath string

// Import modules
module managedEnvironment '../../azresources/modules/main.managedEnvironment.bicep' = {
  name: 'managedEnvironment'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    environment: environment
    virtualNetworkId: virtualNetworkId
    privateDnsZones: privateDnsZones
  }
}

module sqlServer '../../azresources/modules/main.sqlServer.bicep' = {
  name: 'sqlServer'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    environment: environment
    virtualNetworkId: virtualNetworkId
    privateDnsZones: privateDnsZones
    vulnerabilityAssessmentsStorageContainerPath: vulnerabilityAssessmentsStorageContainerPath
  }
}

module storageAccount '../../azresources/modules/main.storageAccount.bicep' = {
  name: 'storageAccount'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    environment: environment
  }
}

module containerApps '../../azresources/modules/main.containerApps.bicep' = {
  name: 'containerApps'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    environment: environment
    managedEnvironmentId: managedEnvironment.outputs.managedEnvironmentId
    sqlServerName: sqlServer.outputs.sqlServerName
    storageAccountName: storageAccount.outputs.storageAccountName
  }
} 

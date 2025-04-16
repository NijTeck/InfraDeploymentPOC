targetScope = 'subscription'

@description('Deployment timestamp for unique naming')
param timestamp string = utcNow('yyyyMMddTHHmm')

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string = deployment().location

@description('Network configuration object.')
param network object

// Extract subscription name for naming resources
// Use displayName instead of name which doesn't exist
var subDisplayName = subscription().displayName
// Remove "sub-" prefix if it exists
var subName = replace(subDisplayName, 'sub-', '')
// Create network resource group name
var networkRgName = '${subName}-${loc}-vnet-rg'

// Create the network resource group explicitly if it doesn't exist
module networkRg 'br/public:avm/res/resources/resource-group:0.4.0' = {
  name: 'deploy-${networkRgName}-${timestamp}'
  params: {
    name: networkRgName
    location: location
    tags: network.resourceGroupTags
  }
}

// Deploy NSGs in the resource group
module nsgDeployment 'br/public:avm/res/network/network-security-group:0.5.0' = [for (subnet, i) in network.subnets: if (subnet.nsg.enabled) {
  name: 'deploy-${subnet.name}-nsg-${timestamp}'
  scope: resourceGroup(network.peering.spokesubid, networkRgName)
  params: {
    name: '${subName}-${toLower(subnet.name)}-${loc}-nsg'
    location: location
  }
  dependsOn: [networkRg]
}]

// Deploy Route Tables in the resource group
module rtDeployment 'br/public:avm/res/network/route-table:0.4.0' = [for (subnet, i) in network.subnets: if (subnet.udr.enabled) {
  name: 'deploy-${subnet.name}-udr-${timestamp}'
  scope: resourceGroup(network.peering.spokesubid, networkRgName)
  params: {
    name: '${subName}-${toLower(subnet.name)}-${loc}-udr'
    location: location
    disableBgpRoutePropagation: subnet.udr.disableBgpRoutePropagation
    routes: [for route in subnet.udr.routes: {
      name: route.name
      properties: {
        addressPrefix: route.properties.addressPrefix
        nextHopType: route.properties.nextHopType
      }
    }]
  }
  dependsOn: [networkRg]
}]

// Deploy the Virtual Network in the spoke subscription
module vnetDeployment 'br/public:avm/res/network/virtual-network:0.5.0' = if (network.deployVnet) {
  name: 'deploy-${network.name}-vnet-${timestamp}'
  scope: resourceGroup(network.peering.spokesubid, networkRgName)
  params: {
    name: '${subName}-${loc}-vnet'
    location: location
    addressPrefixes: network.addressPrefixes
    dnsServers: network.dnsServers
    subnets: [for (subnet, i) in network.subnets: {
      name: subnet.name
      addressPrefix: subnet.addressPrefix
      privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
      networkSecurityGroupResourceId: subnet.nsg.enabled ? nsgDeployment[i].outputs.resourceId : null
      routeTableResourceId: subnet.udr.enabled ? rtDeployment[i].outputs.resourceId : null
    }]
  }
  dependsOn: [
    networkRg
    nsgDeployment
    rtDeployment
  ]
}

// Lock the deployed VNet resource
module vnetLockModule 'submodules/vnet-lock.bicep' = if (!empty(network.lock)) {
  name: 'lock-${network.name}-vnet-${timestamp}'
  scope: resourceGroup(network.peering.spokesubid, networkRgName)
  params: {
    vnetName: '${subName}-${loc}-vnet'
    lock: network.lock
  }
  dependsOn: [vnetDeployment]
}

// Spoke-to-Hub peering module
module spokeToHubPeering '../network/virtualNetwork/vnet-peering.bicep' = if (network.peering.enabled) {
  name: 'spoke-to-hub-peering-${timestamp}'
  scope: resourceGroup(network.peering.spokesubid, networkRgName)
  params: {
    peeringName: '${subName}-to-transit-vnet'
    sourceVnetName: '${subName}-${loc}-vnet'
    targetVnetId: resourceId(network.peering.transitsubid, 'network-vwan-hub-rg', 'Microsoft.Network/virtualNetworks', 'centralus-vnet')
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [vnetDeployment]
}

// Hub-to-Spoke peering module
module hubToSpokePeering '../network/virtualNetwork/vnet-peering.bicep' = if (network.peering.enabled) {
  name: 'hub-to-spoke-peering-${timestamp}'
  scope: resourceGroup(network.peering.transitsubid, 'network-vwan-hub-rg')
  params: {
    peeringName: 'transit-to-${subName}'
    sourceVnetName: 'centralus-vnet'
    targetVnetId: vnetDeployment.outputs.resourceId
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [spokeToHubPeering]
}

// Output the VNet resource ID
output vnetResourceId string = vnetDeployment.outputs.resourceId
output vnetName string = '${subName}-${loc}-vnet'
output resourceGroupName string = networkRgName

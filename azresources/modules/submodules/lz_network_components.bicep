// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 01-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - Implemented Azure Verified Module
//   - Virtual Network (Subnet & Peering)
// [Known Issues]
// - None
// [Change Log]
// - 2025-01-17: Out of Sync
//               Added virtualNetwork_lock (based on content from avm/res/network/virtual-network)
//               - Changed lock-${name} to lock-${network.name}
//               - Pre append lock. with network.
//               Other updates
//               - Renamed resource vnet to virtualNetwork
//               - Changed sourceVnetName: vnet.name to sourceVnetName: virtualNetwork.name
//               - Changed targetVnetId:   vnet.id   to targetVnetId:   virtualNetwork.id
// - 2025-01-07: Bugfix changed var entlzprefix = 'mag' to var entlzprefix = 'mac'
// - 2025-01-06: In Sync, No Changes
// [Change Log: MAG]
// - 2024-12-10: Initial MAG Commit (No Changes)
//               Modified module source path
//               Updated var entlzprefix
//               Changed avm/res/network/route-table:02.2             to 0.4.0'  (Added location, locks)
//               Changed avm/res/network/network-security-group:0.1.3 to 0.5.0'  (Added location)
//               Added Azure Verified Module references for 1) required parameters, 2) non-required parameters (WAF) and 3) non-required parameters (Optional)
// [Change Log: XCLOUD MONOREPO]
// - 2024-10-11: Added take function to spoke to hub peering name
//               Added take function to hub to spoke peering name
// - 2024-04-xx: Via Azure Verified Module
//               - Create Spoke User Defined Route(s)
//               - Create Spoke Network Security Group(s)
//               Additional configuration items
//               - Create Spoke Virtual Network
// - 2024-04-xx: Additional configuration items
//               - Configure Spoke to Hub Peering
//               - Configure Hub to Spoke Peering
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param deploymentTime string = utcNow('yyyyMMddTHHmm')

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string

// Network Parameter(s)
@description('Required: Network configuration for spoke virtual networks.')
param network object

// VARIABLES

var entlzprefix = 'mac'

// TARGET

// OUTPUTS

// ---------------------------------------------------------------------------------------------------------
// Deploy "Required' Networking Components.                                                                *
// ---------------------------------------------------------------------------------------------------------

// Create Spoke User Defined Route(s)
module avm_routeTable 'br/public:avm/res/network/route-table:0.4.0' = [for subnet in network.subnets: if (subnet.udr.enabled) {
  name: 'deploy-${subnet.name}-udr-${deploymentTime}'
  params: {
    // Required parameters
    name: '${network.name}-${toLower(subnet.name)}-${loc}-udr'

    // Non-required parameters (WAF)
    location: location
    /*
    lock: {
      kind: lock.kind
      name: lock.name
    }
    */
    routes: subnet.udr.routes
    // Tags: inherited by policy

    // Non-required parameters (Optional)
    disableBgpRoutePropagation: subnet.udr.disableBgpRoutePropagation
  }
}]

// Create Spoke Network Security Group(s)
module avm_networkSecurityGateway 'br/public:avm/res/network/network-security-group:0.5.0' = [for subnet in network.subnets: if (subnet.nsg.enabled) {
  name: 'deploy-${subnet.name}-nsg-${deploymentTime}'
  params: {
    // Required parameters
    name: '${network.name}-${toLower(subnet.name)}-${loc}-nsg'

    // Non-required parameters (WAF)
    location: location
    // securityRules: []
    // Tags: inherited by policy

    // Non-required parameters (Optional)

  }
}]

// Create Spoke Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  // name: '${network.zone}-${network.name}-${loc}-vnet'
  name: '${network.name}-${loc}-vnet'
  dependsOn: [
    avm_networkSecurityGateway
    avm_routeTable
  ]
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: network.addressPrefixes
    }
    dhcpOptions: {
      dnsServers: network.dnsServers
    }
    subnets: [for (subnet, i) in network.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: (subnet.delegation.enabled) ? [
          {
            name: subnet.delegation.name
            properties: {
              serviceName: subnet.delegation.serviceName
            }
          }
        ] : null
        networkSecurityGroup: (subnet.nsg.enabled) ? {
          id: avm_networkSecurityGateway[i].outputs.resourceId
        } : null
        routeTable: (subnet.udr.enabled) ? {
          id: avm_routeTable[i].outputs.resourceId
        } : null
        // https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy?msclkid=4e0880b6bcf411ec9a65a4250ae42bb5
        // When using the portal to create a private endpoint, the PrivateEndpointNetworkPolicies setting is automatically disabled as part of the create process.
        // Deployment using other clients requires an extra step to change this setting.
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
      }
    }]
  }
}

// -----------------------------------------------------------------------------------------------------------
// Configure Spoke to Hub Peering Relationships.                                                             *
// https://github.com/Azure/bicep-registry-modules/blob/main/avm/res/network/virtual-network/main.bicep#L224 *
// -----------------------------------------------------------------------------------------------------------

resource virtualNetwork_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(network.lock ?? {}) && network.lock.?kind != 'None') {
  name: network.lock.?name ?? 'lock-${network.name}'
    properties: {
      level: network.lock.?kind ?? ''
      notes: network.lock.?kind == 'CanNotDelete'
        ? 'Cannot delete resource or child resources.'
        : 'Cannot delete or modify the resource or child resources.'
    }
    scope: virtualNetwork
  }

// ---------------------------------------------------------------------------------------------------------
// Configure Spoke to Hub Peering Relationships.                                                           *
// ---------------------------------------------------------------------------------------------------------
// Prerequisite
// ---------------------------------------------------------------------------------------------------------
// Get Spoke-Connectivity Resource Group
// Get Transit-Connectivity Resource Group
// Get Transit-Connectivity Virtual Network
// ---------------------------------------------------------------------------------------------------------

// Get Spoke-Connectivity Resource Group
resource spokerg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  // name:  '${network.zone}-${network.name}-${loc}-rg'
  name:  '${network.name}-network-${loc}-rg'
  scope: subscription('${network.peering.spokesubid}')
}

// Get Transit-Connectivity Resource Group
resource transitrg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name:  '${entlzprefix}-${network.zone}-${network.peering.transitrg}-${loc}-rg'
  scope: subscription('${network.peering.transitsubid}')
}

// Get Transit-Connectivity Virtual Network
resource transitvnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: '${entlzprefix}-${network.zone}-${network.peering.transitrg}-${loc}-vnet'
  scope: resourceGroup('${network.peering.transitsubid}','${entlzprefix}-${network.zone}-${network.peering.transitrg}-${loc}-rg')
}

// Configure Spoke to Hub Peering
module spoketohubpeering '../../network/virtualNetwork/vnet-peering.bicep' = if (network.peering.enabled) {
  name: 'deploy-${take(network.name,14)}-to-${network.zone}-hub-peering-${deploymentTime}'
  scope: spokerg
  params: {
    allowVirtualNetworkAccess: true // Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space.
    allowForwardedTraffic: true     // Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network.
    allowGatewayTransit: true       // If gateway links can be used in remote virtual networking to link to this virtual network.
    useRemoteGateways: true         // If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is
                                    // also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true.
                                    // This flag cannot be set if virtual network already has a gateway.
    peeringName: '${network.name}-to-${network.zone}-hub'
    sourceVnetName: virtualNetwork.name
    targetVnetId: transitvnet.id
  }
}

// Configure Hub to Spoke Peering
module hubtospokepeering '../../network/virtualNetwork/vnet-peering.bicep' = if (network.peering.enabled) {
  name: 'deploy-${network.zone}-hub-to-${take(network.name,14)}-peering-${deploymentTime}'
  scope: transitrg
  params: {
    allowVirtualNetworkAccess: true // Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space.
    allowForwardedTraffic: true    // Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network.
    allowGatewayTransit: true       // If gateway links can be used in remote virtual networking to link to this virtual network.
    useRemoteGateways: false        // If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is
                                    // also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true.
                                    // This flag cannot be set if virtual network already has a gateway.
    peeringName: '${network.zone}-hub-to-${network.name}'
    sourceVnetName: transitvnet.name
    targetVnetId: virtualNetwork.id
  }
}

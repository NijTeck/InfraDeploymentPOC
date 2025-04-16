// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 12-2024 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// This resource module creates a virtual network peering connection
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2024-12-23: In Sync, No Changes
// [Change Log: XCLOUD MONOREPO]
// - 04-2024: Initial Commit
// -------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)

// Networking Parameter(s)
@description('Optional: Boolean flag to determine traffic forwarding.  Default: true')
param allowForwardedTraffic bool = true

@description('Optional: Boolean flag to determine if gateway links can be used in remote virtual networking to link to this virtual network.  Default: false')
param allowGatewayTransit bool = false

@description('Optional: Boolean flag to determine virtual network access through the peer.  Default: true')
param allowVirtualNetworkAccess bool = true

@description('Virtual Network Peering Name.')
param peeringName string

@description('Source Virtual Network Name.')
param sourceVnetName string

@description('Target Virtual Network Resource Id.')
param targetVnetId string

@description('Optional: Boolean flag to determine whether remote gateways are used.  Default: false')
param useRemoteGateways bool = false

// VARIABLES

// TARGET

// OUTPUTS

// RESOURCES
resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: '${sourceVnetName}/${peeringName}'
  properties: {
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: targetVnetId
    }
  }
}

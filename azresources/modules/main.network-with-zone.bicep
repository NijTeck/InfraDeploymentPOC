// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 01-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-01-23: MAC Only
//               Changed Spoke Network Resource Group
//               - from ${network.name}-network-${loc}-rg'
//               - to   '${network.zone}-${network.name}-${loc}-rg'
// [Change Log - MAIN.NETWORK.BICEP]
// - 2025-01-06: In Sync, No Changes
// [Change Log: MAG]
// - 2024-12-10: Modified coreNetworkComponents file path
// - 2024-11-23: Initial MAG Commit
// [Change Log: XCLOUD MONOREPO]
// - 2024-10-11: Added switch to deploy NetworkWatchRG
// - 2024-07-11: Changed Module Name
//               Changed Module References
// - 04-2024: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new parameter obtained from pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp                           // original parameter changed to a variable

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string = deployment().location

// Network Parameter(s) - See network module (lz_core_network_components) for additional information.
@description('Required: Network configuration for spoke virtual networks.')
param network object

// VARIABLES

// TARGET
targetScope = 'subscription'

// OUTPUTS

// RESOURCES

// ---------------------------------------------------------------------------------------------------------
// Deploy "Required" and "Optional' Network Components.                                                    *
// ---------------------------------------------------------------------------------------------------------

// Creates a Network Resource Group
resource spokerg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (network.deployVnet) {
  name: (network.deployVnet) ? '${network.zone}-${network.name}-${loc}-rg' : 'skipNetwork'
  // name: (network.deployVnet) ? '${network.name}-network-${loc}-rg' : 'skipNetwork'
  location: location
  tags: network.resourceGroupTags
}

// Creates a Network Resource Group
resource networkWatcherrg 'Microsoft.Resources/resourceGroups@2023-07-01' = if (network.deployVnet && network.deployNetworkWatcherRG) {
  name: (network.deployNetworkWatcherRG) ? 'NetworkWatcherRG' : 'skipNetworkWatcher'
  location: location
  tags: network.resourceGroupTags
}

// Creates Core Network components (network security group(s), route table(s), subnet(s), virtual network, virtual network peering)
module coreNetworkComponents 'submodules/lz_network_components_with_zone.bicep' = if (network.deployVnet) {
  name: (network.deployVnet) ? 'deploy-${network.zone}-${network.name}-${deploymentTime}' : 'skipNetwork'
  // name: (network.deployVnet) ? 'deploy-${network.name}-${deploymentTime}' : 'skipNetwork'
  scope: resourceGroup(spokerg.name)
  params: {
    loc: loc
    location: location
    network: network
  }
}

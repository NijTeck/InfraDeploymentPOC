// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 12-2024 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-03-21: Fixed resource group naming convention
// - 2025-03-21: Fixed reference to resourceGroupsCustom
// - 2024-12-23: In Sync, No Changes
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')
var deploymentTime = timestamp

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string = deployment().location

// Workloads Parameter(s)
@description('Required: Workload configuration items.')
param workloads object = {}

// Get subscription name without "sub-" prefix if it exists
var subName = replace(subscription().displayName, 'sub-', '')

// TARGET
targetScope = 'subscription'

// OUTPUTS
output deployedResourceGroups array = [for (rg, i) in workloads.resourceGroups: resourceGroupName[i].outputs.name]

// RESOURCES

// -------------------------------------------------------------------------------------------------------
// Create Empty Resource Groups (Standard Naming Convention)                                             *
// -------------------------------------------------------------------------------------------------------

module resourceGroupName 'br/public:avm/res/resources/resource-group:0.4.0' = [for resourceGroup in workloads.resourceGroups: {
  name: 'deploy-${resourceGroup.name}-${deploymentTime}'
  params: {
    // Required parameters with corrected naming convention
    name: '${subName}-${resourceGroup.name}-${loc}-rg'

    // Non-required parameters (WAF)
    location: location
    /*
    lock: {
      kind: 'CanNotDelete'
      name: 'myCustomLockName'
    }
    */
    tags: resourceGroup.tags

    // Non-required parameters (Optional)
    roleAssignments: resourceGroup.?roleAssignments ?? []
  }
}]

// -------------------------------------------------------------------------------------------------------
// Create Empty Resource Groups (Non Standard Naming Convention)                                         *
// -------------------------------------------------------------------------------------------------------
// Only create this module if workloads.resourceGroupsCustom exists
module resourceGroupNameCustom 'br/public:avm/res/resources/resource-group:0.4.0' = [for resourceGroupCustom in (workloads.?resourceGroupsCustom ?? []): {
  name: 'deploy-${resourceGroupCustom.name}-${deploymentTime}'
  params: {
    // Required parameters - custom naming is used as provided
    name: '${resourceGroupCustom.name}'

    // Non-required parameters (WAF)
    location: location
    tags: resourceGroupCustom.tags

    // Non-required parameters (Optional)
    roleAssignments: resourceGroupCustom.?roleAssignments ?? []
  }
}]

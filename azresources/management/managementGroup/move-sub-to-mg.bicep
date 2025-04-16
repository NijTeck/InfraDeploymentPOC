// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 12-2024 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// This resource module moves a subscription to a management group.
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2024-12-23: In Sync, No Changes
// [Change Log: XCLOUD MONOREPO]
// - 04-2024: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER
@description('Provide the ID of the management group that you want to move the subscription to.')
param targetMgId string

@description('Provide the ID of the existing subscription to move.')
param subscriptionId string

// VARIABLES

// TARGET
targetScope = 'tenant'

// OUTPUTS

// RESOURCES
resource subscriptionAssociation 'Microsoft.Management/managementGroups/subscriptions@2021-04-01' = {
  name: '${targetMgId}/${subscriptionId}'
}

// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 12-2024 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// This user landing zone module performs the following actions:
// 1 - If applicable, moves Subscription to a specified Management Group.
// 2 - If applicable, grants Subscription Role Assignments based on Security Groups.
// 3 - If applicable, configures Subscription Tags (Warning: Existing tags are overwritten)
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - Management Group Permission Issue (Tenant Deployment requires a higher level of permissions)
// [Change Log]
// - 2025-03-20: Modified management group assignment to skip tenant-level deployment when not needed
//               Improved error handling and made management group move optional
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')
var deploymentTime = timestamp

@description('Location for the deployment.')
param location string = 'centralus'

// Subscription Parameter(s)

// Subscription MG Parameter(s)
// ---------------------------
// WARNING: If a subscription, spans multiple regions and multiple parameter files, these parameters should only be configured once.
// ---------------------------
// Example: Enabled (JSON)
// ---------------------------
// "subscriptionMG":  {
//     "value": {
//         "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
//         "targetMgId": "%target-management-group%"
//     }
// }
// ---------------------------
// Example: Disabled (JSON)
// -----------------------------
// "subscriptionData":  {
//     "value": {
//     }
// }
@description('Optional: Management group configuration containing subscription Id and target management group')
param subscriptionMG object = {}

// Subscription Role Assignment Parameter(s)
// ---------------------------
// Example: Enabled (JSON)
// ---------------------------
// "subscriptionRoleAssignments": {
//     "value": [
//         {
//             "comments": "Built-in Role: Contributor (subscription-name-contributors)",
//             "roleDefinitionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
//             "securityGroupObjectIds": [
//                 "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
//             ]
//         }
//     ]
// }
// ---------------------------
// Example: Disabled (JSON)
// -----------------------------
// "subscriptionRoleAssignments": {
//     "value": [
//      ]
// }
@description('Optional: Array of role assignments at subscription scope.  The array will contain an object with comments, roleDefinitionId and array of securityGroupObjectIds.')
param subscriptionRoleAssignments array = []

// Subscription Tags
// ---------------------------
// Example (JSON)
// -----------------------------
// "subscriptionTags": {
//     "value": {
//         "ServiceClass": "%serviceClass%"    // Non-Production or Production
//     }
// }
// ---------------------------
// Example: Disabled (JSON)
// -----------------------------
// "subscriptionTags": {
//     "value": [
//      ]
// }
@description('Required: A set of key/value pairs of tags assigned to the subscription.')
param subscriptionTags object

// TARGET
targetScope = 'subscription'

// OUTPUTS

// RESOURCES

// -------------------------------------------------------------------------------------------------------
// Deploy "Required" and "Optional' Subscription Components.                                             *
// -------------------------------------------------------------------------------------------------------

module coreSubscriptionComponents 'submodules/lz_core_subscription_components.bicep' = {
  name: 'deploy-coreSubscriptionComponents-${deploymentTime}'
  scope: subscription()
  params: {
    location: location
    subscriptionRoleAssignments: subscriptionRoleAssignments
    subscriptionTags: subscriptionTags
  }
}

// -------------------------------------------------------------------------------------------------------
// Move Subscription to a specific Management Group                                                      *
// Only attempt this if the necessary parameters are provided
// -------------------------------------------------------------------------------------------------------
var hasMgConfig = !empty(subscriptionMG) && contains(subscriptionMG, 'Id') && contains(subscriptionMG, 'targetMgId')

module managementGroup '../management/managementGroup/move-sub-to-mg.bicep' = if (hasMgConfig) {
  scope: tenant()
  name: hasMgConfig ? 'relocate-sub-to-mg-${deploymentTime}' : 'skipMgRelocation'
  params: {
    subscriptionId: hasMgConfig ? subscriptionMG.Id : ''
    targetMgId: hasMgConfig ? subscriptionMG.targetMgId : ''
  }
}

// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 12-2024 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// This user landing zone "core" subscription sub-module performs the following actions:
// 1 - If applicable, assign Subscription Role Assignments based on Security Groups
// 2 - If applicable, configure Subscription Tags (Warning: Existing tags are overwritten)
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - Replace "Assign Subscription Role Assignments" with Azure Verified Module  (12/2024: See avm/ptn/authorization/role-assignment)
// - Replace "Configure Subscription Tags" with Azure Verified Module           (12/2024: Equivalent AVM is unavailable)
// [Known Issues]
// - None
// [Change Log]
// - 2025-03-20: Added location parameter
// - 2024-12-23: In Sync, No Changes
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param deploymentTime string = utcNow('yyyyMMddTHHmm')

@description('Location for the deployment')
param location string

// Subscription Parameter(s)

// Subscription Role Assignments
// -----------------------------
// Example (JSON)
// -----------------------------
// [
//     {
//         "comments": "Built-in Contributor Role",
//         "roleDefinitionId": "b24988ac-6180-42a0-ab88-20f7382dd24c",
//         "securityGroupObjectIds": [
//             'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
//         ]
//     }
// ]
@description('Array of role assignments at subscription scope.  The array will contain an object with comments, roleDefinitionId and array of securityGroupObjectIds.')
param subscriptionRoleAssignments array = []

// Subscription Tags
// -----------------------------
// Example (JSON)
// -----------------------------
// "subscriptionTags": {
//     "value": {
//         "service": "ELZ"
//         "serviceClass": "non-production" or "production"
//     }
// }
// -----------------------------
// Example: Disabled (JSON)
// -----------------------------
// "subscriptionData":  {
//     "value": {
//     }
// }
@description('A set of key/value pairs of tags assigned to the subscription.')
param subscriptionTags object

// VARIABLES

// OUTPUTS

// TARGET SCOPE
targetScope = 'subscription'

// RESOURCES
// -------------------------------------------------------------------------------------------------------
// Assign Subscription Role Assignments
// -------------------------------------------------------------------------------------------------------
module assignSubscriptionRBAC '../../authorization/sub-role-assignment-to-group.bicep' = [for roleAssignment in subscriptionRoleAssignments: {
  name: 'rbac-${roleAssignment.roleDefinitionId}-${deploymentTime}'
  scope: subscription()
  params: {
    roleDefinitionId: roleAssignment.roleDefinitionId
    groupObjectIds: roleAssignment.securityGroupObjectIds
  }
}]

// -------------------------------------------------------------------------------------------------------
// Configure Subscription Tags
// -------------------------------------------------------------------------------------------------------
resource configureSubscriptionTags 'Microsoft.Resources/tags@2022-09-01' = if (!empty(subscriptionTags)) {
  name: 'default'
  scope: subscription()
  properties: {
    tags: subscriptionTags
  }
}

// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 03-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// This module deploys RBAC role assignments for subscriptions and resource groups.
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-03-20: Enhanced error handling for null or empty arrays
//               Improved parameter validation
//               Added detailed comments for better maintainability
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')
var deploymentTime = timestamp

// RBAC Parameter(s)
@description('Required: RBAC configuration containing role assignments at subscription level and resource group level.')
param rbac object

// TARGET
targetScope = 'subscription'

// VARIABLES
var subRoleAssignments = rbac.?subscriptionRoleAssignments ?? []
var rgRoleAssignments = rbac.?resourceGroupRoleAssignments ?? []

// OUTPUTS
output deploymentName string = 'rbac-deployment-${deploymentTime}'
output deployedSubRoleAssignments int = length(subRoleAssignments)
output deployedRgRoleAssignments int = length(rgRoleAssignments)

// RESOURCES

// Deploy subscription level role assignments
// Only deploy when securityGroupObjectIds is not empty
module subscriptionRoleAssignments '../authorization/sub-role-assignment-to-group.bicep' = [for (assignment, i) in subRoleAssignments: if(contains(assignment, 'securityGroupObjectIds') && !empty(assignment.securityGroupObjectIds)) {
  name: 'deploy-sub-role-${i}-${deploymentTime}'
  params: {
    groupObjectIds: assignment.securityGroupObjectIds
    roleDefinitionId: assignment.roleDefinitionId
  }
}]

// Deploy resource group level role assignments
// Only deploy when securityGroupObjectIds and resourceGroup are not empty
module resourceGroupRoleAssignments 'submodules/rg-role-assignment-to-group.bicep' = [for (assignment, i) in rgRoleAssignments: if(contains(assignment, 'securityGroupObjectIds') && !empty(assignment.securityGroupObjectIds) && contains(assignment, 'resourceGroup') && !empty(assignment.resourceGroup)) {
  name: 'deploy-rg-role-${i}-${deploymentTime}'
  scope: resourceGroup(assignment.resourceGroup)
  params: {
    groupObjectIds: assignment.securityGroupObjectIds
    roleDefinitionId: assignment.roleDefinitionId
  }
}]

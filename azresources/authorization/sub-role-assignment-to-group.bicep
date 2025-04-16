// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 03-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// This resource performs a security group "Role Assignment" at the subscription scope.
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-03-20: Fixed issue with role definition ID handling for fully qualified IDs
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// Role Assignment Parameter(s)
@description('Array of Security Group Object Ids.')
param groupObjectIds array = []

@description('Role Definition Id - can be a GUID or fully qualified Azure resource ID.')
param roleDefinitionId string

// VARIABLES
var isFullResourceId = startsWith(roleDefinitionId, '/providers/Microsoft.Authorization/roleDefinitions/') || startsWith(roleDefinitionId, '/subscriptions/')
var fullRoleDefinitionId = isFullResourceId ? roleDefinitionId : subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)

// TARGET
targetScope = 'subscription'

// RESOURCES

// Create role assignments for each group ID
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for groupId in groupObjectIds: if(!empty(groupId)) {
  name: guid(subscription().id, groupId, roleDefinitionId)
  scope: subscription()
  properties: {
    roleDefinitionId: fullRoleDefinitionId
    principalId: groupId
    principalType: 'Group'
  }
}]

// OUTPUTS
output assignedRoleCount int = length(filter(groupObjectIds, groupId => !empty(groupId)))
output assignedRoleIds array = [for (groupId, i) in groupObjectIds: roleAssignment[i].id]

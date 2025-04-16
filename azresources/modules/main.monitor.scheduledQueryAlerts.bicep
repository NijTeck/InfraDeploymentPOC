// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 02-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-02-12: A derivative of main.monitor.scheduledQueryAlert that support the deployment of multiple alerts
// - 2025-02-11: Renamed to main.monitor.scheduledQueryAlert
//               Added / Renamed param ruleResolvedConfiguration with param ruleResolveConfiguration
// - 2025-02-06: Replace br/public:avm/res/insights/scheduled-query-rule:0.3.0 (Does not support customProperties)
//               Added customProperties parameter
//               Temporarily removed ruleResolveRemoved to resolve the following error
//               - The property "ruleResolveConfiguration" is not allowed on objects of type "ScheduledQueryRuleProperties".
//               - Permissible properties include "checkWorkspaceAlertsStorageConfigured", "resolveConfiguration".
// - 2025-01-16: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

@description('Deployment Time is used to create an unique module deployment name.')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new paramater obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp

@description('Enter Location Short Name')
param loc string

@description('Required: Monitor configuration.')
param monitor object

// Subscription Parameter(s)
// -----------------------------
// Example:(JSON)
// -----------------------------
// "Subscription":{
//     "value":{
//         "name": "%subscription-name%"            // If applicable, remove "sub-" from subscription name (default)
//     }
// }
@description('Required: Subscription configuration.')
param subscription object

// TARGET
targetScope = 'subscription'

// VARIABLES

// OUTPUT

// RESOURCE

// -------------------------------------------------------------------------------------------------------
// Create Monitor Resource Group  (Standard Naming Convention)                                           *
// -------------------------------------------------------------------------------------------------------
resource monitorRG 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: '${subscription.name}-monitor-${loc}-rg'
}

//module avm_scheduledQueryAlert 'br/public:avm/res/insights/scheduled-query-rule:0.3.0' = {
module avm_scheduledQueryAlert '../insights/schedule-query-rules.bicep' = [for scheduleQueryAlert in monitor.scheduleQueryAlerts: {
  name: 'deploy-${replace(scheduleQueryAlert.alertName,' ','-')}-${deploymentTime}'
  scope: monitorRG
  params: {
    // Required parameters
    criterias: scheduleQueryAlert.alertCriteria
    name: scheduleQueryAlert.alertName
    // Non-required parameters
    actions: scheduleQueryAlert.alertActions
    alertDescription: scheduleQueryAlert.alertDescription
    alertDisplayName: scheduleQueryAlert.alertDisplayName
    autoMitigate: scheduleQueryAlert.autoMitigate
    customProperties: scheduleQueryAlert.customProperties
    enabled: scheduleQueryAlert.isEnabled
    evaluationFrequency: scheduleQueryAlert.alertEvalFrequency
    kind: scheduleQueryAlert.alertKind
    location: scheduleQueryAlert.alertLocation
    roleAssignments: scheduleQueryAlert.roleAssignmentsList
    // ruleResolveConfiguration: scheduleQueryAlert.ruleResolveConfiguration
    severity: scheduleQueryAlert.alertSeverity
    skipQueryValidation: scheduleQueryAlert.skipQueryValidation
    scopes: scheduleQueryAlert.scopes
    windowSize: scheduleQueryAlert.alertWindowSize
  }
}]

// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 12-2024 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - -WhatIf results do not reflect all updates made via the avm_serviceHealthAlert module.
// [Change Log]
// - 2024-12-23: In Sync, No Changes
// [Change Log: MAC]
// - 2024-12-16: Initial MAC Commit
// [Change Log: MAG]
// - 2024-12-13: Renamed Network Object to Subscription Object (more accurately reflects value)
// - 2024-12-02: Initial MAG Commit
//               Changed avm/res/insights/action-group:0.2.4       to 0.4.0 (Added location)
//               Changed avm/res/insights/activity-log-alert:0.1.2 to 0.3.0 (Added location)
//               Added Azure Verified Module references for 1) required parameters, 2) non-required parameters (WAF) and 3) non-required parameters (Optional)
// [Change Log: XCLOUD MONOREPO]
// - 2024-10-21: Add Create Activity Log Alert
// - 2024-07-11: Changed Module Name
// - 2024-05-17: Updated Monitor Template
// - 2024-04-XX: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new parameter obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp                           // original parameter changed to a variable

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string = deployment().location

// Monitor Parameter(s)
// -----------------------------
// Example:(JSON)
// -----------------------------
//  "monitor": {
//      "value": {
//          "actionGroup":{
//              ** see parameter file **
//          }
//          "resourceGroupTags": {
//              "Criticality": "XXXXXXXXX"          //Non-Production, Non-Critical, Production (default), Business-Critical, Mission-Critical
//              "ProductId": "PL24_1698",
//              "WorkloadName": "Data Center Monitor"
//          }
//          "serviceHealth":{
//              ** See parameter file **
//          }
//          "webhookProperties":{
//              "owner": "%subscription-name%",     // Alert Owner
//              "serviceClass": "%serviceClass%"    // Non-Production or Production
//          }
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
// VARIABLES

var serviceHealthActions = [
  {
    actionGroupId: avm_actionGroup.outputs.resourceId
    webhookProperties: monitor.serviceHealth.webhookProperties
  }
]

// TARGET
targetScope = 'subscription'

// OUTPUTS

// RESOURCES
// -------------------------------------------------------------------------------------------------------
// Create Monitor Resource Group  (Standard Naming Convention)                                           *
// -------------------------------------------------------------------------------------------------------
resource monitorRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${subscription.name}-monitor-${loc}-rg'
  location: location
  tags: monitor.resourceGroupTags
}

// -------------------------------------------------------------------------------------------------------
// Create Action Group                                     .                                             *
// -------------------------------------------------------------------------------------------------------
module avm_actionGroup 'br/public:avm/res/insights/action-group:0.4.0' = {
  scope: monitorRG
  name: 'deploy-actionGroupName-${deploymentTime}'
  params: {
    // Required parameters
    groupShortName: monitor.actionGroup.actionGroupShortName
    name: '${subscription.name}-${monitor.actionGroup.actionGroupName}'

    // Non-required parameters (WAF)
    location: 'global'
    // Tags: inherited by policy

    // Non-required parameters (Optional)
    webhookReceivers: monitor.actionGroup.webhookReceivers
  }
}

// -------------------------------------------------------------------------------------------------------
// Create Service Health Alert                                   .                                       *
// -------------------------------------------------------------------------------------------------------
module avm_serviceHealthAlert 'br/public:avm/res/insights/activity-log-alert:0.3.0' = {
  scope: monitorRG
  name: 'deploy-serviceHealthAlert-${deploymentTime}'
  params: {
    // Required parameters
    name: monitor.serviceHealth.alertRuleName
    conditions: monitor.serviceHealth.condition

    // Non-required parameters (WAF)
    actions: serviceHealthActions
    location: 'global'
    // Tags: inherited by policy

    // Non-required parameters (Optional)
    alertDescription: monitor.serviceHealth.alertRuleDescription
  }
}

// -------------------------------------------------------------------------------------------------------
// Create Activity Log Alert                                   .                                         *
// -------------------------------------------------------------------------------------------------------
module avm_logAlert 'br/public:avm/res/insights/activity-log-alert:0.3.0' = [for activityLogAlert in monitor.activityLogAlerts: {
  scope: monitorRG
  name: '${replace(activityLogAlert.name,' ','')}-${deploymentTime}'
  params: {
    // Required parameters
    name: activityLogAlert.name
    conditions: activityLogAlert.conditions

    // Non-required parameters (WAF)
    actions: activityLogAlert.actions
    location: 'global'
    /*
    Tags: inherited by policy
    */

    // Non-required parameters (Optional)
    alertDescription: activityLogAlert.alertDescription
    enabled: activityLogAlert.isEnabled
  }
}]

// PARAMETER

@description('Deployment Time is used to create an unique module deployment name.')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new paramater obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp

@description('Name of the alert processing rule.')
param aprName string

@description('Array of actions to be taken by the rule. This will be the addition or removal action groups from alerts that trigger. Also requires "ActionType" which can be either "AddActionGroups" or "RemoveAllActionGroups".')
param aprActions array

@description('Description of the rule. Should include the information on when this rule should be used and whether it contains a schedule.')
param aprDescription string

@description('Conditions that will trigger the processing rule.')
param aprConditions array

@description('Whether the processing rule is enabled on creation or not.')
param isEnabled bool

@description('Location for the alert. Default is global. Not to be confused with scopes.')
param location string 

@description('If a role is required to be assigned as part of the alert, those values can be defined in an array here.')
param roleAssignmentsList array

@description('The scope for the alert processing rule. It is recommended to scope this at the subscription level. Use either subscription().id or "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" notation.')
param scopes array = [
  subscription().id
 ]

@description('A schedule can be defined. This can be used to ensure alerts trigger all the time or it can be used to suppress alerts during non-business hours.')
param schedule object

// OUTPUT

output alertProcessingRule string = avm_actionRule.outputs.resourceId

// RESOURCE

module avm_actionRule 'br/public:avm/res/alerts-management/action-rule:0.2.0' = {
  name: 'deploy-scheduled-query-alert-${deploymentTime}'
  params: {
    // Required parameters
    name: aprName
    // Non-required parameters
    actions: aprActions
    aprDescription: aprDescription
    conditions: aprConditions
    enabled: isEnabled
    location: location
    roleAssignments: roleAssignmentsList
    scopes: scopes
    schedule: schedule
  }
}

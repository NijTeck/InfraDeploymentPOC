// PARAMETER

@description('Deployment Time is used to create an unique module deployment name.')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new paramater obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp

@description('Name of the scheduled query alert.')
param alertName string

@description('Criteria for the alert. Should include the query, time aggregation, metric measure column, dimensions, resource ID, operator, threshold, and the failing periods.')
param alertCriteria object

@description('Actions to be taken when the alert triggers. Can define action groups, webhooks, ect.')
param alertActions array

@description('Alert description.')
param alertDescription string

@description('Provides a description of the alert which will be visible in the portal and if email notifications are sent.')
param alertDisplayName string

@description('Determines whether the alert resolves itself or not. If not enabled and the alert criteria is repeatedly met during the lookback period, alerts will continue to fire. It is recommended to enable this.')
param autoMitigate bool

@description('Whether the alet is enabled on creation or not.')
param isEnabled bool

@allowed([
  'PT5M'
  'PT15M'
  'PT30M'
  'PT1H'
])
@description('This is how often the alert criteria is evaluated in ISO 8601 format.')
param alertEvalFrequency string

@allowed([
  'LogAlert'
  'LogToMetric'
])
@description('Defines the type of alert. LogAlert requires additional parameters defined in this template.')
param alertKind string

@description('Azure region where this alert will be located.')
param alertLocation string

@description('If a role is required to be assigned as part of the alert, those values can be defined in an array here.')
param roleAssignmentsList array

@description('Defines the configuration for resolving fired alerts.')
param ruleResolvedConfiguration object

@allowed([
  0
  1
  2
  3
  4
])
@description('Alert severity in numberical value. Lower is more severe; default value is 3.')
param alertSeverity int

@description('Determines whether the query for the log alert is validated or skipped on creation. It is recommended to have this set to false.')
param skipQueryValidation bool

@description('The scope for the log query alert. It is recommended to scope this at the subscription level using "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx" notation.')
param scopes array = []

@allowed([
  'P1D'
  'PT12H'
  'PT15M'
  'PT1H'
  'PT1M'
  'PT30M'
  'PT5M'
  'PT6H'
])
@description('Period of time that is used to monitor alert activity based on the threshold. Uses ISO 8601 format.')
param alertWindowSize string

// OUTPUT

output queryAlert string = avm_scheduledQueryAlert.outputs.resourceId

// RESOURCE

module avm_scheduledQueryAlert 'br/public:avm/res/insights/scheduled-query-rule:0.3.0' = {
  name: 'deploy-scheduled-query-alert-${deploymentTime}'
  params: {
    // Required parameters
    criterias: alertCriteria
    name: alertName
    // Non-required parameters
    actions: alertActions
    alertDescription: alertDescription
    alertDisplayName: alertDisplayName
    autoMitigate: autoMitigate
    enabled: isEnabled
    evaluationFrequency: alertEvalFrequency
    kind: alertKind
    location: alertLocation
    roleAssignments: roleAssignmentsList
    ruleResolveConfiguration: ruleResolvedConfiguration
    severity: alertSeverity
    skipQueryValidation: skipQueryValidation
    scopes: scopes
    windowSize: alertWindowSize
  }
}

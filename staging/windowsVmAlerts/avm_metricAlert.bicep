// PARAMETER

@description('Deployment Time is used to create an unique module deployment name.')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new paramater obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp    

@description('Name of the metrics alert rule.')
param alertName string

@description('Criteria for the alert. This maps to the odata.type field and defines what triggers the alert.')
param alertCriteria object

@description('Actions to be taken when the alert triggers. Can define action groups, webhooks, ect.')
param alertActions array

@description('Location for the alert. The default value is global.')
param alertLocation string

@description('If a role is required to be assigned as part of the alert, those values can be defined in an array here.')
param roleAssignmentsList array

@description('Provides a description of the alert which will be visible in the portal and if email notifications are sent.')
param alertDescription string

@description('Determines whether the alert resolves itself or not. If not enabled and the alert criteria is repeatedly met during the lookback period, alerts will continue to fire. It is recommended to enable this.')
param autoMitigate bool

@description('Whether the alet is enabled on creation or not.')
param isEnabled bool

@allowed([
  'PT15M'
  'PT1H'
  'PT1M'
  'PT30M'
  'PT5M'
])
@description('This is how often the alert criteria is evaluated in ISO 8601 format.')
param alertEvalFrequency string

@allowed([
  0
  1
  2
  3
  4
])
@description('Alert severity in numberical value. Lower is more severe; default value is 3.')
param alertSeverity int

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

@description('This is required if the alertCriteriaType is "MultipleresourceMultipleMetricCriteria". Defines the resource type. IE, "microsoft.compute/virtualmachines". This can be commented out if it is determined to not be necessary.')
param alertTargetResourceType string 

@description('This is required if the alertCriteriaType is "MultipleresourceMultipleMetricCriteria". Defines the resource region. This can be commented out if it is not necessary.')
param alertTargetResourceRegion string 

// OUTPUT

output metricAlert string = avm_metricAlert.outputs.resourceId

// RESOURCE

module avm_metricAlert 'br/public:avm/res/insights/metric-alert:0.3.0' = {
  name: 'deploy-metric-alert-${deploymentTime}'
  params: {
    // Required parameters
    criteria: alertCriteria
    name: alertName
    // Non-required parameters
    actions: alertActions
    location: alertLocation
    roleAssignments: roleAssignmentsList
    alertDescription: alertDescription
    autoMitigate: autoMitigate
    enabled: isEnabled
    evaluationFrequency: alertEvalFrequency
    severity: alertSeverity
    windowSize: alertWindowSize
    targetResourceType: alertTargetResourceType
    targetResourceRegion: alertTargetResourceRegion
  }
}

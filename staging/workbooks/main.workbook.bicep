// PARAMETER

@description('The friendly name for the workbook that is used in the Gallery or Saved List.  This name must be unique within a resource group.')
param workbookDisplayName string = 'Sample Workbook'

@description('The unique guid for this workbook instance')
param workbookId string = newGuid()

@description('The id of resource instance to which the workbook will be associated')
param workbookSourceId string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/microsoft.insights/components/appinsights'

@description('The gallery that the workbook will been shown under. Supported values include workbook, tsg, etc. Usually, this is \'workbook\'')
param workbookType string = 'workbook'

// VARIABLES

// TARGET

// OUTPUTS
output workbookId string = workbookId_resource.id

// RESOURCES

resource workbookId_resource 'microsoft.insights/workbooks@2022-04-01' = {
  name: workbookId
  location: resourceGroup().location
  kind: 'shared'
  properties: {
    category: workbookType
    displayName: workbookDisplayName
    serializedData: loadTextContent('azure_hybrid_benefit_workbook/hybrid_benefit_tracker_workbook.json')
    sourceId: workbookSourceId
    version: '1.0'
  }
}

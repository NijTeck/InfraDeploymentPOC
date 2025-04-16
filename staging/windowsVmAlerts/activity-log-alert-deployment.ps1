# Script to iterate through the activity log alerts and deploy one resource per parameter file 

# define the resource group and template file
$resourceGroup = "azure-monitor-test"
#$templateFile = "avm_metricAlert.bicep"
$templateFile = "avm_scheduledQueryAlert.bicep"

# retrieve parameter files in the current directory
#$templateType = "metric"
$templateType = "scheduledQueryAlert"
$parameterFiles = Get-ChildItem -path. -filter "*$templateType*.json" | Where-Object {$_.Name -notmatch "template"}

# loop through each parameter file and deploy the template

foreach ($paramFile in $parameterFiles) {
    Write-Host "Deploying with parameter file: $($paramFile.Name)"
    az deployment group create --resource-group $resourceGroup --template-file $templateFile --parameters @$paramFile
}
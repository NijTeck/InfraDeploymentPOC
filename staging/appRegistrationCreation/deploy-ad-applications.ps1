# Deploy Azure AD Applications for Dev and Prod

# Parameters
$environments = @('dev', 'prod')
$baseAppName = 'Icertis Contact Intelligence SSO'
$resourceGroupName = 'your-resource-group-name'  # Replace with your resource group name

# Function to deploy application and generate details
function Deploy-AzureAdApplication {
    param(
        [string]$Environment
    )

    Write-Host "Deploying Azure AD Application for $Environment environment"

    # Create Application
    $deploymentName = "IcertisContactIntelligence-$Environment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $deployment = New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile 'C:\AzureIACodebase\InfraDeployment%20POC\staging\appRegistrationCreation\azure-ad-app-registration.bicep' `
        -environmentName $Environment `
        -appDisplayName "$baseAppName" `
        -Verbose

    # Check deployment success
    if ($deployment.ProvisioningState -eq 'Succeeded') {
        # Get Tenant ID
        $tenantId = (az account show | ConvertFrom-Json).tenantId

        # Get Application details
        $appId = $deployment.Outputs.applicationId.Value
        $objectId = $deployment.Outputs.applicationObjectId.Value

        # Create Client Secret
        $secret = az ad app credential reset --id $appId --display-name "ClientSecret-$Environment" | ConvertFrom-Json

        # Construct OAuth 2.0 token endpoint
        $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

        # Output detailed information
        Write-Host "`n=== $Environment Application Details ==="
        Write-Host "Secret: $($secret.password)"
        Write-Host "AppId: $appId"
        Write-Host "OAuth 2.0 token endpoint (v2): $tokenEndpoint"
        Write-Host "ObjectID: $objectId"
        Write-Host "Directory (tenant) ID: $tenantId"
        Write-Host "=================================`n"

        return @{
            Environment = $Environment
            Secret = $secret.password
            AppId = $appId
            TokenEndpoint = $tokenEndpoint
            ObjectId = $objectId
            TenantId = $tenantId
        }
    }
    else {
        Write-Error "Deployment for $Environment environment failed"
    }
}

# Deploy applications for each environment
$deploymentResults = @()
foreach ($env in $environments) {
    $result = Deploy-AzureAdApplication -Environment $env
    $deploymentResults += $result
}

# Export the results to a JSON file
$deploymentResults | ConvertTo-Json | Out-File -FilePath ".\app-deployment-results.json"

Write-Host "Azure AD Application deployments completed."
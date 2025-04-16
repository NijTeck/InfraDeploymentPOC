# SSL Certificate Deployment for Application Gateway
# This script offers options to handle SSL certificates when deploying an Application Gateway

$resourceGroupName = "f9pciprdcusnetrg"
$deploymentName = "deploy-agency-appgw-$(Get-Date -Format 'yyyyMMddHHmmss')"
$location = "centralus"
$appGwName = "prod-multisites-apgw"
$bicepFile = "prod-multisites-apgw.bicep"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "    APPLICATION GATEWAY DEPLOYMENT WITH SSL CERTIFICATE" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Resource Group: $resourceGroupName"
Write-Host "App Gateway: $appGwName"
Write-Host "Template File: $bicepFile"
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan

# Check/create public IP first
$publicIpName = "prod-multisites-agw-pip"
Write-Host "Checking/creating public IP $publicIpName..." -ForegroundColor Cyan
$publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpName -ErrorAction SilentlyContinue

if (-not $publicIp) {
    Write-Host "Creating public IP..." -ForegroundColor Yellow
    $publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpName -Location $location -AllocationMethod Static -Sku Standard -Zone @("1", "2", "3")
    Write-Host "Public IP created: $($publicIp.IpAddress)" -ForegroundColor Green
} else {
    Write-Host "Using existing public IP: $($publicIp.IpAddress)" -ForegroundColor Green
}

# Present options for SSL certificate
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "SSL CERTIFICATE OPTIONS:" -ForegroundColor Yellow
Write-Host "1. Deploy without SSL certificate (HTTP only)"
Write-Host "2. Provide a PFX certificate file"
Write-Host "3. Use a Key Vault certificate"
Write-Host "4. Exit without deploying"

$option = Read-Host "Select an option (1-4)"

# Create a temporary Bicep file to modify based on the selected option
$tempBicepFile = "temp-$bicepFile"
Copy-Item -Path $bicepFile -Destination $tempBicepFile -Force

# Create a temporary parameters file
$paramsFile = "temp-params.json"

switch ($option) {
    "1" {
        Write-Host "Deploying without SSL certificate..." -ForegroundColor Yellow
        
        # Modify the Bicep file to remove SSL certificate and use HTTP
        $bicepContent = Get-Content $tempBicepFile -Raw
        
        # Remove SSL certificate section completely (empty array)
        $bicepContent = $bicepContent -replace "sslCertificates:\s*\[\s*\{[\s\S]*?\}\s*\]", "sslCertificates: []"
        
        # Fix backend HTTP settings - Change port to 80 when using HTTP protocol for backends
        $backendSettingsPattern = "backendHttpSettingsCollection:\s*\[\s*\{[\s\S]*?\}\s*\]"
        $newBackendSettings = @"
backendHttpSettingsCollection: [
      {
        name: 'prod-agency-backend-settings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGateways_prod_multisites_apgw_name, 'prod-agency-backend-probe')
          }
        }
      }
    ]
"@
        $bicepContent = $bicepContent -replace $backendSettingsPattern, $newBackendSettings
        
        # Update probe protocol to HTTP as well
        $probePattern = "probes:\s*\[\s*\{[\s\S]*?\}\s*\]"
        $newProbe = @"
probes: [
      {
        name: 'prod-agency-backend-probe'
        properties: {
          protocol: 'Http'
          path: '/status-0123456789abcdef'
          interval: 60
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-504'
            ]
          }
        }
      }
    ]
"@
        $bicepContent = $bicepContent -replace $probePattern, $newProbe
        
        # Completely replace the httpListeners section to ensure no SSL references remain
        $listenerPattern = "httpListeners:\s*\[\s*\{[\s\S]*?\}\s*\]"
        $newHttpListener = @"
httpListeners: [
      {
        name: 'agency-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateways_prod_multisites_apgw_name, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateways_prod_multisites_apgw_name, 'port_80')
          }
          protocol: 'Http'
          hostName: 'agency.flyfrontier.com'
          hostNames: []
          requireServerNameIndication: false
          customErrorConfigurations: []
        }
      }
    ]
"@
        $bicepContent = $bicepContent -replace $listenerPattern, $newHttpListener
        
        # Write the modified content back to the file
        $bicepContent | Set-Content $tempBicepFile
        
        # Create parameters file
        @"
{
    "applicationGateways_prod_multisites_apgw_name": {
        "value": "$appGwName"
    },
    "virtualNetworks_f9pciprdcusdmzvnet_externalid": {
        "value": "/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/virtualNetworks/f9pciprdcusdmzvnet"
    },
    "publicIPAddresses_prod_multisites_agw_pip_externalid": {
        "value": "$($publicIp.Id)"
    }
}
"@ | Out-File $paramsFile
    }
    "2" {
        Write-Host "Using a PFX certificate file..." -ForegroundColor Yellow
        $pfxPath = Read-Host "Enter the full path to your PFX certificate file"
        $pfxPassword = Read-Host "Enter the certificate password" -AsSecureString
        
        if (-not (Test-Path $pfxPath)) {
            Write-Host "Certificate file not found. Exiting." -ForegroundColor Red
            exit 1
        }
        
        # Read certificate data
        $pfxBytes = [System.IO.File]::ReadAllBytes($pfxPath)
        $pfxBase64 = [System.Convert]::ToBase64String($pfxBytes)
        $pfxPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxPassword))
        
        # Create parameters file with certificate data
        @"
{
    "applicationGateways_prod_multisites_apgw_name": {
        "value": "$appGwName"
    },
    "virtualNetworks_f9pciprdcusdmzvnet_externalid": {
        "value": "/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/virtualNetworks/f9pciprdcusdmzvnet"
    },
    "publicIPAddresses_prod_multisites_agw_pip_externalid": {
        "value": "$($publicIp.Id)"
    },
    "certificateData": {
        "value": "$pfxBase64"
    },
    "certificatePassword": {
        "value": "$pfxPasswordPlain"
    }
}
"@ | Out-File $paramsFile
        
        # Modify the Bicep file to include certificate data from parameters
        $bicepContent = Get-Content $tempBicepFile -Raw
        
        # Add new parameters for certificate
        $paramSection = "param applicationGateways_prod_multisites_apgw_name string = 'prod-multisites-apgw'
param virtualNetworks_f9pciprdcusdmzvnet_externalid string = '/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/virtualNetworks/f9pciprdcusdmzvnet'
param publicIPAddresses_prod_multisites_agw_pip_externalid string = '/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/publicIPAddresses/prod-multisites-agw-pip'
param certificateData string = ''
param certificatePassword string = ''"
        
        $bicepContent = $bicepContent -replace "param applicationGateways_prod_multisites_apgw_name string.*?param publicIPAddresses_prod_multisites_agw_pip_externalid string.*?\n", $paramSection
        
        # Update SSL certificate section to use parameters
        $sslCertSection = "sslCertificates: [
      {
        name: 'agency.flyfrontier.com'
        properties: {
          data: certificateData
          password: certificatePassword
        }
      }
    ]"
        
        $bicepContent = $bicepContent -replace "sslCertificates:\s*\[\s*\{[\s\S]*?\}\s*\]", $sslCertSection
        
        # Write the modified content back to the file
        $bicepContent | Set-Content $tempBicepFile
    }
    "3" {
        Write-Host "Using a Key Vault certificate..." -ForegroundColor Yellow
        $keyVaultName = Read-Host "Enter your Key Vault name"
        $secretName = Read-Host "Enter the secret name for the certificate"
        
        # Get Key Vault secret ID
        try {
            $secret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName
            $secretId = $secret.Id
            
            if (-not $secretId) {
                throw "Secret not found"
            }
            
            Write-Host "Retrieved secret from Key Vault successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to retrieve secret from Key Vault: $_" -ForegroundColor Red
            exit 1
        }
        
        # Create parameters file with Key Vault reference
        @"
{
    "applicationGateways_prod_multisites_apgw_name": {
        "value": "$appGwName"
    },
    "virtualNetworks_f9pciprdcusdmzvnet_externalid": {
        "value": "/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/virtualNetworks/f9pciprdcusdmzvnet"
    },
    "publicIPAddresses_prod_multisites_agw_pip_externalid": {
        "value": "$($publicIp.Id)"
    },
    "keyVaultSecretId": {
        "value": "$secretId"
    }
}
"@ | Out-File $paramsFile
        
        # Modify the Bicep file to use Key Vault reference
        $bicepContent = Get-Content $tempBicepFile -Raw
        
        # Add new parameter for Key Vault secret ID
        $paramSection = "param applicationGateways_prod_multisites_apgw_name string = 'prod-multisites-apgw'
param virtualNetworks_f9pciprdcusdmzvnet_externalid string = '/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/virtualNetworks/f9pciprdcusdmzvnet'
param publicIPAddresses_prod_multisites_agw_pip_externalid string = '/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/publicIPAddresses/prod-multisites-agw-pip'
param keyVaultSecretId string = ''"
        
        $bicepContent = $bicepContent -replace "param applicationGateways_prod_multisites_apgw_name string.*?param publicIPAddresses_prod_multisites_agw_pip_externalid string.*?\n", $paramSection
        
        # Update SSL certificate section to use Key Vault
        $sslCertSection = "sslCertificates: [
      {
        name: 'agency.flyfrontier.com'
        properties: {
          keyVaultSecretId: keyVaultSecretId
        }
      }
    ]"
        
        $bicepContent = $bicepContent -replace "sslCertificates:\s*\[\s*\{[\s\S]*?\}\s*\]", $sslCertSection
        
        # Write the modified content back to the file
        $bicepContent | Set-Content $tempBicepFile
    }
    "4" {
        Write-Host "Exiting without deployment." -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host "Invalid option. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Confirm deployment
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Ready to deploy Application Gateway $appGwName to $resourceGroupName" -ForegroundColor Yellow
$confirm = Read-Host "Proceed with deployment? (y/n)"

if ($confirm -ne 'y') {
    Write-Host "Deployment cancelled by user." -ForegroundColor Yellow
    # Clean up temporary files
    Remove-Item $tempBicepFile -Force -ErrorAction SilentlyContinue
    Remove-Item $paramsFile -Force -ErrorAction SilentlyContinue
    exit 0
}

# Upgrade Bicep first
Write-Host "Checking for Bicep updates..." -ForegroundColor Cyan
az bicep upgrade

# Deploy using Azure CLI
Write-Host "Deploying Application Gateway..." -ForegroundColor Cyan
Write-Host "This may take several minutes..." -ForegroundColor Yellow

$deploymentResult = az deployment group create --resource-group $resourceGroupName --name $deploymentName --template-file $tempBicepFile --parameters @$paramsFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Host $deploymentResult
} else {
    Write-Host "Deployment successful!" -ForegroundColor Green
    
    # Get the application gateway details
    $appGw = Get-AzApplicationGateway -ResourceGroupName $resourceGroupName -Name $appGwName -ErrorAction SilentlyContinue
    
    if ($appGw) {
        $frontendConfig = $appGw.FrontendIPConfigurations[0]
        $pipId = $frontendConfig.PublicIPAddress.Id
        
        # Fixed: Get public IP by ID using Get-AzResource first, then Get-AzPublicIpAddress by name and resource group
        $pipResource = Get-AzResource -ResourceId $pipId
        $pip = Get-AzPublicIpAddress -ResourceGroupName $pipResource.ResourceGroupName -Name $pipResource.Name
        
        Write-Host "=======================================================" -ForegroundColor Green
        Write-Host "Application Gateway deployed successfully!" -ForegroundColor Green
        Write-Host "Name: $appGwName"
        Write-Host "Public IP: $($pip.IpAddress)"
        Write-Host "Hostname: agency.flyfrontier.com"
        if ($option -eq "1") {
            Write-Host "Protocol: HTTP (no SSL certificate)"
        } else {
            Write-Host "Protocol: HTTPS (with SSL certificate)"
        }
        Write-Host "=======================================================" -ForegroundColor Green
    }
}

# Clean up temporary files
Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
Remove-Item $tempBicepFile -Force -ErrorAction SilentlyContinue
Remove-Item $paramsFile -Force -ErrorAction SilentlyContinue

Write-Host "Done!" -ForegroundColor Green
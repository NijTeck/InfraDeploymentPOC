# Azure AD Application Deployment for Icertis Contact Intelligence

## Prerequisites

1. Azure CLI installed
2. PowerShell
3. Required PowerShell Modules:
   - Az.Resources
   - Microsoft.Graph

## Installation Steps

1. Install required PowerShell modules:
```powershell
Install-Module -Name Az.Resources -Force
Install-Module -Name Microsoft.Graph -Force
```

2. Log in to Azure:
```powershell
az login
az account set --subscription "YourSubscriptionName"
```

3. Update the deployment script:
   - Replace `$resourceGroupName` with your target resource group name
   - Verify the base application name and other parameters

## Deployment

Run the deployment script:
```powershell
.\deploy-ad-applications.ps1
```

## Configuration Details

The script will create two Azure AD applications:
1. Icertis Contact Intelligence SSO - dev
2. Icertis Contact Intelligence SSO - prod

### Key Features
- Multiple org sign-in support
- Implicit and ID token flows
- Custom app roles
- OAuth2 permissions
- Parental control settings

## Troubleshooting

- Ensure you have sufficient permissions in Azure AD
- Check Azure CLI and PowerShell module versions
- Verify subscription and resource group details

## Security Considerations

- The password credential is set to expire in 2 years
- Applications are configured with minimal necessary permissions
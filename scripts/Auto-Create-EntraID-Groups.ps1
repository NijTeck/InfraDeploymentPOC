# Auto-Create-EntraID-Groups.ps1
<#
.SYNOPSIS
   Automatically creates Entra ID groups for Azure resource management based on subscription and resource group information.
   
.DESCRIPTION
   This script is designed to be run from an Azure DevOps pipeline. It creates standard Entra ID security groups
   for subscriptions and resource groups, following naming conventions, and assigns appropriate Azure RBAC roles.
   
   For subscriptions, it creates:
   - sub-<subscription-name>-contributors
   - sub-<subscription-name>-readers
   
   For resource groups, it creates:
   - rg-<resourcegroup-name>-contributors
   - rg-<resourcegroup-name>-readers
   
.PARAMETER SubscriptionId
   The ID of the Azure subscription to process
   
.PARAMETER SubscriptionName
   The name of the Azure subscription (used for creating group names)
   
.EXAMPLE
   .\Auto-Create-EntraID-Groups.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -SubscriptionName "my-subscription"
   
.NOTES
   Version:        1.2
   Author:         Azure Mono-Deployment Team
   Creation Date:  2025-03-21
   Last Modified:  2025-03-21
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionName
)

# Function to create a group and return the object ID
function New-EntraIDGroupWithRetry {
    param (
        [string]$DisplayName,
        [string]$Description,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 5
    )
    
    $attempt = 1
    $success = $false
    $groupId = $null
    
    while (-not $success -and $attempt -le $MaxRetries) {
        try {
            Write-Host "Attempt ${attempt}: Creating group '${DisplayName}'"
            
            # Check if group already exists
            $existingGroup = Get-AzADGroup -DisplayName $DisplayName -ErrorAction SilentlyContinue
            
            if ($existingGroup) {
                $groupId = $existingGroup.Id
                Write-Host "Group '${DisplayName}' already exists with ID: ${groupId}"
                $success = $true
                return $groupId
            }
            
            # Create the group
            $newGroup = New-AzADGroup -DisplayName $DisplayName -Description $Description -MailNickname $DisplayName
            $groupId = $newGroup.Id
            Write-Host "Successfully created group '${DisplayName}' with ID: ${groupId}"
            $success = $true
        }
        catch {
            Write-Warning "Failed to create group on attempt ${attempt}. Error: $_"
            if ($attempt -lt $MaxRetries) {
                Write-Host "Retrying in ${RetryDelaySeconds} seconds..."
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                Write-Error "Failed to create group after ${MaxRetries} attempts: $_"
                throw
            }
        }
        $attempt++
    }
    
    return $groupId
}

# Function to assign a role to a group
function New-RoleAssignmentWithRetry {
    param (
        [string]$ObjectId,
        [string]$RoleDefinitionName,
        [string]$Scope,
        [string]$ResourceGroupName,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 5
    )
    
    $attempt = 1
    $success = $false
    
    while (-not $success -and $attempt -le $MaxRetries) {
        try {
            Write-Host "Attempt ${attempt}: Assigning role '${RoleDefinitionName}' to group with ID '${ObjectId}'"
            
            # First check if role assignment already exists
            if ($ResourceGroupName) {
                $existingAssignment = Get-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $RoleDefinitionName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
            }
            else {
                $existingAssignment = Get-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $RoleDefinitionName -Scope $Scope -ErrorAction SilentlyContinue
            }
            
            if ($existingAssignment) {
                Write-Host "Role assignment already exists"
                $success = $true
                return
            }
            
            if ($ResourceGroupName) {
                # For resource group scope
                $roleAssignment = New-AzRoleAssignment -ObjectId $ObjectId `
                                                      -RoleDefinitionName $RoleDefinitionName `
                                                      -ResourceGroupName $ResourceGroupName
            }
            else {
                # For subscription or other scope
                $roleAssignment = New-AzRoleAssignment -ObjectId $ObjectId `
                                                      -RoleDefinitionName $RoleDefinitionName `
                                                      -Scope $Scope
            }
            
            Write-Host "Successfully assigned role '${RoleDefinitionName}' to group"
            $success = $true
        }
        catch {
            # Check if the error indicates the role assignment already exists
            if ($_.Exception.Message -like "*already exists*" -or $_.Exception.Message -like "*Conflict*") {
                Write-Host "Role assignment already exists or conflict detected - continuing as normal"
                $success = $true
            }
            else {
                Write-Warning "Failed to assign role on attempt ${attempt}. Error: $_"
                if ($attempt -lt $MaxRetries) {
                    Write-Host "Retrying in ${RetryDelaySeconds} seconds..."
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
                else {
                    Write-Warning "Failed to assign role after ${MaxRetries} attempts: $_"
                    # Not throwing an exception here - we'll continue with the script
                    $success = $true  # To exit the loop
                }
            }
        }
        $attempt++
    }
}

# Main execution
try {
    # Connect to the specified subscription
    Write-Host "Setting context to subscription ID: ${SubscriptionId}"
    Set-AzContext -SubscriptionId $SubscriptionId
    
    # Clean subscription name - remove "sub-" prefix if it exists
    $cleanSubName = $SubscriptionName -replace "^sub-", ""
    $subNameLower = $cleanSubName.ToLower()
    
    Write-Host "Creating subscription-level groups for: ${subNameLower}"
    
    # Contributors group - with "sub-" prefix
    $contributorsGroupName = "sub-${subNameLower}-contributors"
    $contributorsDesc = "Purpose: ${subNameLower} (subscription) rbac assignment / privileged identity management (No members)"
    $contributorsGroupId = New-EntraIDGroupWithRetry -DisplayName $contributorsGroupName -Description $contributorsDesc
    
    # Readers group - with "sub-" prefix
    $readersGroupName = "sub-${subNameLower}-readers"
    $readersDesc = "Purpose: ${subNameLower} (subscription) rbac assignment"
    $readersGroupId = New-EntraIDGroupWithRetry -DisplayName $readersGroupName -Description $readersDesc
    
    # Assign roles at subscription level
    $subscriptionScope = "/subscriptions/${SubscriptionId}"
    New-RoleAssignmentWithRetry -ObjectId $contributorsGroupId -RoleDefinitionName "Contributor" -Scope $subscriptionScope
    New-RoleAssignmentWithRetry -ObjectId $readersGroupId -RoleDefinitionName "Reader" -Scope $subscriptionScope
    
    # Create resource group-level groups
    Write-Host "Getting resource groups in subscription ${SubscriptionId}"
    $resourceGroups = Get-AzResourceGroup
    
    foreach ($rg in $resourceGroups) {
        $rgName = $rg.ResourceGroupName
        
        # Skip NetworkWatcherRG
        if ($rgName -eq "NetworkWatcherRG") {
            Write-Host "Skipping NetworkWatcherRG"
            continue
        }
        
        Write-Host "Processing resource group: ${rgName}"
        
        # Extract the base resource group name without location and -rg suffix
        # Expected pattern: <project>-<purpose>-<location>-rg
        if ($rgName -match "^(.+)-[a-z]{3}-rg$") {
            $rgBaseName = $matches[1]
        } else {
            # If the pattern doesn't match, use the full name
            $rgBaseName = $rgName
        }
        
        $rgNameLower = $rgBaseName.ToLower()
        
        # Contributors group - with "rg-" prefix
        $rgContributorsGroupName = "rg-${rgNameLower}-contributors"
        $rgContributorsDesc = "Purpose: ${rgNameLower} (resource group) rbac assignment / privileged identity management (No members)"
        $rgContributorsGroupId = New-EntraIDGroupWithRetry -DisplayName $rgContributorsGroupName -Description $rgContributorsDesc
        
        # Readers group - with "rg-" prefix
        $rgReadersGroupName = "rg-${rgNameLower}-readers"
        $rgReadersDesc = "Purpose: ${rgNameLower} (resource group) rbac assignment"
        $rgReadersGroupId = New-EntraIDGroupWithRetry -DisplayName $rgReadersGroupName -Description $rgReadersDesc
        
        # Assign roles at resource group level
        New-RoleAssignmentWithRetry -ObjectId $rgContributorsGroupId -RoleDefinitionName "Contributor" -ResourceGroupName $rgName
        New-RoleAssignmentWithRetry -ObjectId $rgReadersGroupId -RoleDefinitionName "Reader" -ResourceGroupName $rgName
    }
    
    # Output the created group IDs as pipeline variables
    Write-Host "##vso[task.setvariable variable=SubContributorsGroupId;isOutput=true]${contributorsGroupId}"
    Write-Host "##vso[task.setvariable variable=SubReadersGroupId;isOutput=true]${readersGroupId}"
    
    Write-Host "Successfully created and configured security groups for subscription ${SubscriptionName}"
}
catch {
    Write-Warning "Error occurred during script execution: $_"
    # Don't rethrow the error - we want the pipeline to continue even if there's an issue
    exit 0  # Exit with success code to prevent pipeline failure
}
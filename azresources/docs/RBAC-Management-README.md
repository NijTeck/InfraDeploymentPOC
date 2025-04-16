# RBAC Management in Azure Mono-Deployment Solution

This document explains how Role-Based Access Control (RBAC) is implemented in the Azure Mono-Deployment solution for centralized management of security groups and role assignments.

## Overview

The RBAC management solution automates the creation of Entra ID security groups and assigns appropriate RBAC roles to these groups at both subscription and resource group levels. This approach follows the principle of least privilege and ensures consistent security controls across all deployments.

## Security Group Naming Convention

The solution follows these naming conventions for security groups:

- **Subscription-level groups**:
  - `<subscription-name>-contributors` - For users who need contributor access to the subscription
  - `<subscription-name>-readers` - For users who need read-only access to the subscription

- **Resource group-level groups**:
  - `rg-<resourcegroup-name>-contributors` - For users who need contributor access to a specific resource group
  - `rg-<resourcegroup-name>-readers` - For users who need read-only access to a specific resource group

## Implementation Details

### Security Group Creation

The pipeline creates security groups during deployment using the `Auto-Create-EntraID-Groups.ps1` PowerShell script, which:

1. Creates the required subscription-level security groups
2. Creates the required resource group-level security groups (excluding NetworkWatcherRG)
3. Records the Object IDs of created groups for subsequent role assignments

### Role Assignments

After security groups are created, the pipeline assigns appropriate roles:

1. **Subscription-level roles**:
   - Assigns the Contributor role to the `<subscription-name>-contributors` group
   - Assigns the Reader role to the `<subscription-name>-readers` group

2. **Resource group-level roles**:
   - Assigns the Contributor role to each `rg-<resourcegroup-name>-contributors` group
   - Assigns the Reader role to each `rg-<resourcegroup-name>-readers` group

### Deployment Process

The RBAC management process in the pipeline follows these steps:

1. The pipeline first runs the security group creation task using a dedicated Azure PowerShell task
2. The security group Object IDs are passed to subsequent tasks as pipeline variables
3. RBAC deployments are performed using Azure Bicep templates
4. Resource deployments proceed only after security groups and role assignments are in place

## Files and Components

The RBAC management solution consists of the following key files:

- **`scripts/Auto-Create-EntraID-Groups.ps1`**: PowerShell script that creates Entra ID security groups
- **`azresources/modules/main.rbac.bicep`**: Bicep template for deploying RBAC role assignments
- **`azresources/modules/submodules/rg-role-assignment-to-group.bicep`**: Bicep module for resource group-level role assignments
- **`azresources/authorization/sub-role-assignment-to-group.bicep`**: Bicep module for subscription-level role assignments
- **`templates/rbac-deployment-task.yml`**: Pipeline template for RBAC deployment tasks

## Usage in Subscription Templates

To implement RBAC management for a new subscription in the pipeline:

1. Add a new stage in the main `azure-pipelines.yml` file for the subscription
2. Include a job to run the RBAC deployment task before resource deployment jobs
3. Configure the master subscription template to deploy resources with appropriate dependencies on the RBAC job

## Identity Requirements

The Azure DevOps service connections used by the pipeline must have:

1. **Microsoft Graph API permissions**:
   - Group.ReadWrite.All - For creating and managing Entra ID security groups
   
2. **Azure RBAC permissions**:
   - User Access Administrator (at subscription level) - For assigning roles
   - Management Group Contributor (at tenant level) - Only if using the Management Group assignment feature

## Troubleshooting

Common issues and their solutions:

- **Group creation fails**: Verify that the service principal has sufficient Graph API permissions
- **Role assignment fails**: Ensure the service principal has User Access Administrator role
- **Duplicate groups**: The script checks for existing groups before creating new ones to avoid duplicates
- **Permission errors**: Review the pipeline logs for specific error messages related to permissions
- **Management Group assignment failures**: For moving subscriptions to management groups, ensure the service principal has appropriate permissions at the tenant level

## Recent Improvements

1. **Enhanced Error Handling**: All Bicep modules now include robust error handling for empty parameters
2. **Management Group Assignment Fix**: The subscription module now properly handles management group assignment scenarios
3. **RBAC Deployment Optimization**: The RBAC deployment process has been streamlined for better reliability
4. **Validation Logic**: Role definition ID formats are now validated before deployment
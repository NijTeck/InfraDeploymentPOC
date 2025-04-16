## Start of Document Repo 
https://learn.microsoft.com/en-us/azure/architecture/web-apps/guides/enterprise-app-patterns/overview 

## End of Document Repo 

Role-Based Access Control (RBAC) Solution Overview
I've created a comprehensive solution for managing security groups and role assignments in your Azure Mono-Deployment pipeline. This solution follows your requirements and implements them in a maintainable, automated manner.
Key Components

Automated Security Group Creation

For each subscription: <subscription-name>-contributors and <subscription-name>-readers
For each resource group: rg-<resourcegroup-name>-contributors and rg-<resourcegroup-name>-readers
NetworkWatcherRG is specifically excluded as requested


Role Assignment

Contributor and Reader roles assigned at subscription level
Contributor and Reader roles assigned at resource group level


Pipeline Integration

RBAC tasks run first, before resource deployments
Security group IDs are captured and passed to subsequent tasks



Implementation Files
Here's a breakdown of the files I've created and their purposes:
1. PowerShell Scripts

scripts/Auto-Create-EntraID-Groups.ps1
A robust script that creates Entra ID security groups for subscriptions and resource groups, with built-in retry logic and error handling.

2. Bicep Templates

azresources/modules/main.rbac.bicep
The main Bicep template for RBAC deployments, orchestrating subscription and resource group role assignments.
azresources/modules/submodules/rg-role-assignment-to-group.bicep
A module for resource group-level role assignments.

3. Pipeline Templates

templates/master-subscription-template.yml (Updated)
The master template for subscription deployments, now with integrated security group creation and role assignment.
templates/rbac-deployment-task.yml
A dedicated task template for RBAC deployments.
templates/subscription-pipeline-template.yml
A simpler template focused specifically on security group management.

4. Main Pipeline

azure-pipelines.yml (Updated)
The main pipeline file now includes dedicated jobs for security group setup before resource deployment.

5. Documentation

RBAC-Management-README.md
Comprehensive documentation explaining the RBAC solution and how to use it.

Implementation Notes

Security and Idempotency

The scripts check for existing groups before creating new ones
Retry logic handles transient failures
Role assignments are checked to prevent duplicate assignments


Performance Optimization

Security group creation is done in a single script execution per subscription
Role assignments use efficient Bicep deployment


Extension Points

The solution can be easily extended to support custom roles
Additional role assignments can be added through parameter files
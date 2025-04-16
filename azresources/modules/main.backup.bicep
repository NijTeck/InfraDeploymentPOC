// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 02-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-02-03: Added optional support for a Backup Vault Resource Guard
// - 2024-12-23: In Sync
//               Changed avm/res/data-protection/backup-vault:0.4.2 to 0.7.0
//               Added Azure Verified Module references for 1) required parameters, 2) non-required parameters (WAF) and 3) non-required parameters (Optional)
//               Resolved role assignment issue by replacing random (avm_backupVault.name) value with static (BackupVaultName) value.
// [Change Log: XCLOUD MONOREPO]
// - 2024-10-08: Added backup vault resource group tags
// - 2024-09-11: Added resource lock, removed default loc and subName value
// - 2024-08-07: Added section label, Changed Module Name, Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new parameter obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string = deployment().location

@description('Backup Vault Resource Group Tags')
param resourceGroupTags object

@description('Network Name')
param subName string

@description('PostgreSQL Flexible Server Backup Policies to be created in the Backup Vault')
param PostgreflexbackupPolicies array

@description('MySQL Backup Policies to be created in the Backup Vault')
param MySqlbackupPolicies array

@description('Optional. The vault redundancy level to use.')
@allowed([
  'LocallyRedundant'
  'GeoRedundant'
  'ZoneRedundant'
])
param storageType string

@description('Role Assignments of the vault MI against the subscription')
param roleAssignments array = []

@description('Resource lock configuration for the Backup Vault')
param lock object = {
  kind: 'CanNotDelete'
  name: 'Cannot delete resource or child resources'
}

param backupVaultSecurity object = {
  immutabilityState: 'Unlocked'
  softDeleteRetentionDurationInDays: 14
  softDeleteState: 'AlwaysOn'
}

@description('Enable attachment of Resource Guard to Backup Vault')
param attachResourceGuard bool = false

@description('Resource Guard Resource ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.DataProtection/resourceGuards/resourceguardname')
param resourceGuardId string

param resourceGuardOperationDetails array

// TARGET
targetScope = 'subscription'

// VARIABLES

// Define the short name storage type for the vault

// Original Code
// var storagetypeshort = (storageType == 'GeoRedundant') ? 'grs' : (storageType == 'LocallyRedundant') ? 'lrs' : (storageType == 'ZoneRedundant') ? 'zrs' :  (storageType == 'ReadAccessGeoZoneRedundant') ? 'ragzrs' : null

// Suggested Code
var storagetypeshortLookup = {
  GeoRedundant: 'grs'
  LocallyRedundant: 'lrs'
  ZoneRedundant: 'zrs'
  ReadAccessGeoZoneRedundant: 'ragzrs'
}
// var storagetypeshort = contains(storagetypeshortLookup, '${storageType}') ? storagetypeshortLookup['${storageType}'] : null

// Updated Code (Linting Recommmendation)
var storagetypeshort = storagetypeshortLookup[?storageType] ?? null

// Define the name of the Backup Vault
var BackupVaultName = '${subName}-${storagetypeshort}-${loc}-bv'

// Creates the PostgreSQL Flex backup policy objects based on the vaules from the 'PostgreflexbackupPolicies' array.
var PostgreFlexPoliciesvar = [for policy in PostgreflexbackupPolicies: {
  properties:{
    policyRules: concat(
      policy.yearlyRetention > 0 ? [
      {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.yearlyRetention}Y'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: false
        name: 'Yearly'
        objectType: 'AzureRetentionRule'
      }
      ] : [],
      policy.monthlyRetention > 0 ? [
        {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.monthlyRetention}M'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: false
        name: 'Monthly'
        objectType: 'AzureRetentionRule'
      }
      ] : [],
      [
      {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.weeklyRetention}W'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: false
        name: 'Weekly'
        objectType: 'AzureRetentionRule'
      }
      {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.dailyRetention}D'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: true
        name: 'Default'
        objectType: 'AzureRetentionRule'
      }
      {
        backupParameters: {
          backupType: 'Full'
          objectType: 'AzureBackupParams'
        }
        trigger: {
          schedule: {
            repeatingTimeIntervals: [
              'R/2024-07-21T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-22T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-23T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-17T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-18T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-19T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-20T${policy.repeatingtimeinterval}-05:00/P1W'
            ]
            timeZone: 'Mountain Time'
          }
          taggingCriteria: concat(
            (policy.yearlyRetention > 0) ? [{
              tagInfo: {
                tagName: 'Yearly'
                id: 'Yearly_'
              }
              taggingPriority: 10
              isDefault: false
              criteria: [
                {
                  absoluteCriteria: [
                    'FirstOfYear'
                  ]
                  objectType: 'ScheduleBasedBackupCriteria'
                }
              ]
            }] :[],
            [
            {
              tagInfo: {
                tagName: 'Monthly'
                id: 'Monthly_'
              }
              taggingPriority: 15
              isDefault: false
              criteria: [
                {
                  absoluteCriteria: [
                    'FirstOfMonth'
                  ]
                  objectType: 'ScheduleBasedBackupCriteria'
                }
              ]
            }
            {
              tagInfo: {
                tagName: 'Weekly'
                id: 'Weekly_'
              }
              taggingPriority: 20
              isDefault: false
              criteria: [
                {
                  absoluteCriteria: [
                    'FirstOfWeek'
                  ]
                  objectType: 'ScheduleBasedBackupCriteria'
                }
              ]
            }
            {
              tagInfo: {
                tagName: 'Default'
                id: 'Default_'
              }
              taggingPriority: 99
              isDefault: true
            }
          ])
          objectType: 'ScheduleBasedTriggerContext'
        }
        dataStore: {
          dataStoreType: 'VaultStore'
          objectType: 'DataStoreInfoBase'
        }
        name: 'BackupWeekly'
        objectType: 'AzureBackupRule'
      }
      ])
    datasourceTypes: [
      'Microsoft.DBforPostgreSQL/flexibleServers'
    ]
    objectType: 'BackupPolicy'
  }
  name: policy.name
  }
  ]


// Creates the MySQL backup policy objects based on the vaules from the 'MySqlbackupPolicies' array.
var MysqlbackupPoliciesvar = [for policy in MySqlbackupPolicies: {
  properties:{
    policyRules: concat(
      policy.yearlyRetention > 0 ? [
      {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.yearlyRetention}Y'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: false
        name: 'Yearly'
        objectType: 'AzureRetentionRule'
      }
      ] : [],
      policy.monthlyRetention > 0 ? [
        {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.monthlyRetention}M'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: false
        name: 'Monthly'
        objectType: 'AzureRetentionRule'
      }
      ] : [],
      [
      {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.weeklyRetention}W'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: false
        name: 'Weekly'
        objectType: 'AzureRetentionRule'
      }
      {
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P${policy.dailyRetention}D'
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
        isDefault: true
        name: 'Default'
        objectType: 'AzureRetentionRule'
      }
      {
        backupParameters: {
          backupType: 'Full'
          objectType: 'AzureBackupParams'
        }
        trigger: {
          schedule: {
            repeatingTimeIntervals: [
              'R/2024-07-21T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-22T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-23T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-17T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-18T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-19T${policy.repeatingtimeinterval}-05:00/P1W'
              'R/2024-07-20T${policy.repeatingtimeinterval}-05:00/P1W'
            ]
            timeZone: 'Mountain Time'
          }
          taggingCriteria: concat(
            (policy.yearlyRetention > 0) ? [{
              tagInfo: {
                tagName: 'Yearly'
                id: 'Yearly_'
              }
              taggingPriority: 10
              isDefault: false
              criteria: [
                {
                  absoluteCriteria: [
                    'FirstOfYear'
                  ]
                  objectType: 'ScheduleBasedBackupCriteria'
                }
              ]
            }]: [],
            [
            {
              tagInfo: {
                tagName: 'Monthly'
                id: 'Monthly_'
              }
              taggingPriority: 15
              isDefault: false
              criteria: [
                {
                  absoluteCriteria: [
                    'FirstOfMonth'
                  ]
                  objectType: 'ScheduleBasedBackupCriteria'
                }
              ]
            }
            {
              tagInfo: {
                tagName: 'Weekly'
                id: 'Weekly_'
              }
              taggingPriority: 20
              isDefault: false
              criteria: [
                {
                  absoluteCriteria: [
                    'FirstOfWeek'
                  ]
                  objectType: 'ScheduleBasedBackupCriteria'
                }
              ]
            }
            {
              tagInfo: {
                tagName: 'Default'
                id: 'Default_'
              }
              taggingPriority: 99
              isDefault: true
            }
          ])
          objectType: 'ScheduleBasedTriggerContext'
        }
        dataStore: {
          dataStoreType: 'VaultStore'
          objectType: 'DataStoreInfoBase'
        }
        name: 'BackupWeekly'
        objectType: 'AzureBackupRule'
      }
    ])
    datasourceTypes: [
      'Microsoft.DBforMySQL/flexibleServers'
    ]
    objectType: 'BackupPolicy'
  }
  name: policy.name
  }
  ]

// This variable combines the backup policies for PostgreFlex and Mysql databases.
// It concatenates the values of the 'PostgreFlexPoliciesvar' and 'MysqlbackupPoliciesvar' variables.
var backupPolicies = concat(PostgreFlexPoliciesvar, MysqlbackupPoliciesvar)

// RESOURCES

// Creates Resource Group for Backup Vault
resource BackupvaultRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${subName}-backupvault-${loc}-rg'
  location: location
  tags: resourceGroupTags
}

// Module to deploy the Backup Vault
module avm_backupVault 'br/public:avm/res/data-protection/backup-vault:0.7.0' = {
  name: 'deploy-backup-vault-${deploymentTime}'
  scope: BackupvaultRG
  params: {
    // Required parameters
    name: BackupVaultName

    // Non-required parameters (WAF)
    azureMonitorAlertSettingsAlertsForAllJobFailures: 'Enabled'
    backupPolicies: backupPolicies
    location: location
    lock: (!empty(lock ?? {}) && lock.?kind != 'None') ? {
      kind: lock.kind
      name: lock.name
    } : {}
    managedIdentities: {
      systemAssigned: true
    }
    // Tags: inherited by policy

    // Non-required parameters (Optional)
    dataStoreType: 'OperationalStore'
    enableTelemetry: false
    featureSettings: {
    }
    securitySettings: {
      immutabilitySettings: {
        state: backupVaultSecurity.immutabilityState
      }
      softDeleteSettings: {
        retentionDurationInDays: (backupVaultSecurity.softDeleteState == 'AlwaysOn' || backupVaultSecurity.softDeleteState == 'On') ? backupVaultSecurity.softDeleteRetentionDurationInDays : null
        state: backupVaultSecurity.softDeleteState
      }
    }
    type: storageType
  }
}

/*
  This resource block creates role assignments for the backup vault.
  It iterates over the 'roleAssignments' array and creates a role assignment for each item.
  The 'name' property is set to a unique identifier generated using the 'guid' function.
  The 'properties' object contains the following properties:
    - 'roleDefinitionId': The ID of the role definition, constructed using the subscription ID and role definition ID from the 'roleAssignment' item.
    - 'principalId': The system-assigned managed identity principal ID of the backup vault.
    - 'principalType': The principal type from the 'roleAssignment' item.
*/
resource backupVault_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
      name: guid(BackupVaultName,roleAssignment.roleDefinitionId)
      properties: {
        roleDefinitionId: resourceId(subscription().subscriptionId, 'Microsoft.Authorization/roleDefinitions', roleAssignment.roleDefinitionId)
        principalId: avm_backupVault.outputs.systemAssignedMIPrincipalId
        principalType: roleAssignment.principalType
      }
    }
  ]

// Module to protect the Backup Vault with Resource Guard
module resourceguard '../dataProtection/backupVault/backupVault_resourceGuard.bicep' = if (attachResourceGuard) {
  name: 'deploy-resource-guard-proxy-${deploymentTime}'
  scope: BackupvaultRG
  params: {
    resourceGuardId: resourceGuardId
    resourceGuardOperationDetails: resourceGuardOperationDetails
    avm_backupVaultname: BackupVaultName
  }
  dependsOn: [
    avm_backupVault
  ]
}

// OUTPUTS
output BackupVaultName string = avm_backupVault.outputs.name
output PrincipalId string = avm_backupVault.outputs.systemAssignedMIPrincipalId

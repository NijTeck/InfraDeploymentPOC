// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 01-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - If multiple daily backups are required, the number of actual backups may not match the number of desired backups.
// [Change Log]
// - 2025-02-26: Added Recovery Vault Restore Resource Group ManagedBy property
// - 2025-02-07: Changed param storageAccount default from Standard_GRS to GeoRedundant
//               Added param attachResourceGuard
//               Added param resourceGuardID
//               Added param resourceGuardOperationDetails
//               Changed how hourySchedule.scheduleWindowsDuration is calculated
//               Changed avm/res/recovery-services/vault:0.5.1'       to 0.6.0
//               - Added storageType
//               - Added multiUserAuthentication
//               - Added softDeleteSettings
//               Added module to protect the Recovery Vault with Resource Guard
// - 2025-01-03: Temporarily, removed "proof of concept" code to address a known issues by
//               replaced scheduleWindowDuration: policy.hourlyduration with scheduleWindowDuration: policy.hourlyfrequency
// - 2024-12-23: In Sync
//               Changed Recovery Vault Lock methodology to match Backup Vault methodology.
// - 2024-12-20: Changed avm/res/recovery-services/vault:0.2.2'       to 0.5.1 (Added Location, Lock)
//               Added Azure Verified Module references for 1) required parameters, 2) non-required parameters (WAF) and 3) non-required parameters (Optional)
//               Replace Private Endpoint DNS Zone ID with Private DNS Zone Group for Private Endpoint
//               Modified isCompression and isSqlCompression settings
//               Synchronized XCLOUD to MAC
//               Synchronized MAC to MAG
// [Change Log: XCLOUD MONOREPO]
// - 2024-11-19: Renamed recovery vault resource group
// - 2024-10-08: Added recovery vault resource group tags
// - 2024-09-11: removed default subName value
// - 2024-08-07: Removed empty lines, added section label, no code changes
// - 2024-07-11: Changed Module Name
// - 2024-XX-XX: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// General Parameter(s)
@description('Deployment Time is used to create an unique module deployment name')
param timestamp string = utcNow('yyyyMMddTHHmm')         // new paramater obtained from monorepo pipeline
// param deploymentTime string = utcNow('yyyyMMddTHHmm') // original parameter used in code base
var deploymentTime = timestamp

@description('Enter Location Short Name')
param loc string

@description('Optional: Location for the deployment.')
param location string = deployment().location

@description('Resource lock configuration for the Recovery Vault')
param lock object = {
  kind: 'CanNotDelete'
  name: 'Cannot delete resource or child resources'
}

@description('Network Name')
param subName string

@description('Recovery Services Vault Name')
param RSVName string

@description('Recovery ServicesVault configuration items')
param recoveryVault object

@description('Backup Storage Type')
param storageType string = 'GeoRedundant'

@description('Backup Policy settings to be created in the Recovery Services Vault')
param VMBackupPolicies array

@description('Backup Policy settings to be created in the Recovery Services Vault')
param SQLBackupPolicies array

@description('Resource Group Name for the Azure Backup restore Resource Group')
param RestoreResourceGroupName string

@description('Recovery Vault & Recovery Vault Restore Resource Group Tags')
param resourceGroupTags object

@description('Enable Private Endpoint for Recovery Services Vault')
param enablePrivateEndpoint bool = false

@description('Private Endpoint Subnet ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.Network/virtualNetworks/vnetName/subnets/subnetName')
param PrivateEndpointSubnetID string = ''

// @description('Private Endpoint DNS Zone ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.Network/privateDnsZones/privateDnsZoneName')
// param PrivateEndpointDNSZoneID string = ''

@description('Private DNS Zone Group for Private Endpoint')
param PrivateDNSZoneGroup object

@description('Diagnostic Settings for Recovery Services Vault')
param diagnosticSettings object

@description('Enable attachment of Resource Guard to Recovery Vault')
param attachResourceGuard bool = false

@description('Resource Guard Resource ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.DataProtection/resourceGuards/resourceguardname')
param resourceGuardId string

param resourceGuardOperationDetails array

// VARIABLES
var VMbackupPoliciesvar =  [for policy in VMBackupPolicies: {
  name: policy.name
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRPDetails:{
      azureBackupRGNamePrefix: RestoreResourceGroupName
    }
    instantRPRetentionRangeInDays: policy.instantRestorePointRetention
    policyType: 'V2'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: policy.frequency
      hourlySchedule: (policy.frequency == 'Hourly') ? {
        interval: policy.hourlyfrequency
        scheduleWindowDuration: (contains(policy,'hourlyduration')) ? policy.hourlyduration : policy.hourlyfrequency
        scheduleWindowStartTime: policy.startTime
      }: null
      dailySchedule: (policy.frequency == 'Daily') ? {
        scheduleRunTimes: [
          policy.startTime
        ]
      }: null
      weeklySchedule: (policy.frequency == 'Weekly') ? {
        scheduleRunDays: [
          'Sunday'
        ]
        scheduleRunTimes: [
          policy.startTime
        ]
      }: null
    }
    retentionPolicy:{
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: policy.dailyRetention
          durationType: 'Days'
        }
        retentionTimes: [
          policy.startTime
        ]
      }
      weeklySchedule: (policy.weeklyRetention > 0) ? {
          daysOfTheWeek: [
            'Sunday'
          ]
          retentionDuration: {
            count: policy.weeklyRetention
            durationType: 'Weeks'
          }
          retentionTimes: [
            policy.startTime
          ]
        }: {}
      monthlySchedule: (policy.monthlyRetention > 0) ? {
        retentionDuration: {
          count: policy.monthlyRetention
          durationType: 'Months'
        }
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: [
          policy.startTime
        ]
        retentionScheduleFormatType: 'Daily'
      }: null
      yearlySchedule: (policy.yearlyRetention > 0) ? {
        monthsOfYear: [
            'January'
          ]
        retentionDuration: {
          count: policy.yearlyRetention
          durationType: 'Years'
        }
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: [
          policy.startTime
        ]
        retentionScheduleFormatType: 'Daily'
      } : null
    }
    timeZone: 'Mountain Time'
  }
}]

var SQLbackupPoliciesvar = [for sqlpolicy in SQLBackupPolicies: {
    name: sqlpolicy.name
    properties: {
      backupManagementType: 'AzureWorkload'
      settings: {
        isCompression: false
        issqlcompression: false
        timeZone: 'Mountain Time'
      }
      subProtectionPolicy: [
        {
          policyType: 'Full'
          retentionPolicy: {
            monthlySchedule: {
              retentionDuration: {
                count: sqlpolicy.monthlyRetention
                durationType: 'Months'
              }
              retentionScheduleFormatType: 'Weekly'
              retentionScheduleWeekly: {
                daysOfTheWeek: [
                  'Sunday'
                ]
                weeksOfTheMonth: [
                  'First'
                ]
              }
              retentionTimes: [
                sqlpolicy.startTime
              ]
            }
            retentionPolicyType: 'LongTermRetentionPolicy'
            dailySchedule: (sqlpolicy.dailyRetention > 0) ? {
              retentionDuration: {
                count: sqlpolicy.dailyRetention
                durationType: 'Days'
              }
              retentionTimes: [
                sqlpolicy.startTime
              ]
            } : null
            weeklySchedule: (sqlpolicy.weeklyRetention > 0) ? {
              daysOfTheWeek: [
                'Sunday'
              ]
              retentionDuration: {
                count: sqlpolicy.weeklyRetention
                durationType: 'Weeks'
              }
              retentionTimes: [
                sqlpolicy.startTime
              ]
            }: null
            yearlySchedule: (sqlpolicy.yearlyRetention > 0 )? {
              monthsOfYear: [
                'January'
              ]
              retentionDuration: {
                count: sqlpolicy.yearlyRetention
                durationType: 'Years'
              }
              retentionScheduleFormatType: 'Weekly'
              retentionScheduleWeekly: {
                daysOfTheWeek: [
                  'Sunday'
                ]
                weeksOfTheMonth: [
                  'First'
                ]
              }
              retentionTimes: [
                sqlpolicy.startTime
              ]
            }: null
          }
          schedulePolicy: {
            schedulePolicyType: 'SimpleSchedulePolicy'
            scheduleRunFrequency: 'Daily'
            scheduleRunDays: [
              'Sunday'
            ]
            scheduleRunTimes: [
              sqlpolicy.startTime
            ]
            scheduleWeeklyFrequency: 0
          }
        }
        {
          policyType: 'Log'
          retentionPolicy: {
            retentionDuration: {
              count: sqlpolicy.LogBackupRetention
              durationType: 'Days'
            }
            retentionPolicyType: 'SimpleRetentionPolicy'
          }
          schedulePolicy: {
            scheduleFrequencyInMins: sqlpolicy.LogBackupFrequencyInMinutes
            schedulePolicyType: 'LogSchedulePolicy'
          }
        }
      ]
      workLoadType: 'SQLDataBase'
    }
  }
]

var policies = concat(VMbackupPoliciesvar, SQLbackupPoliciesvar)
// Creates a Recovery Vault Resource Group

// TARGET
targetScope = 'subscription'

// OUTPUTS

// RESOURCES
// Create Recovery Vault Resource Group
resource recoveryVaultRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${subName}-recoveryvault-${loc}-rg'
  location: location
  tags: resourceGroupTags
}

/*
// Create Recovery Vault Restore Resource Group
resource recoveryVaultRestoreRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${subName}-recoveryvault-restore-${loc}-rg'
  location: location
  tags: resourceGroupTags
}
  */

// Create Recovery Vault Restore Resource Group
resource recoveryVaultRestoreRG1 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${subName}-recoveryvault-restore-${loc}-rg1'
  location: location
  tags: resourceGroupTags
  managedBy: 'subscriptions/${subscription().subscriptionId}/providers/Microsoft.RecoveryServices/'
}

// Module to deploy the Recovery Vault
module avm_recoveryVault 'br/public:avm/res/recovery-services/vault:0.6.0' = {
  name: 'deploy-recovery-vault-${deploymentTime}'
  scope: recoveryVaultRG
  params:{
    // Required parameters
    name: RSVName

    // Non-required parameters (WAF)
    backupConfig: {
      enhancedSecurity: recoveryVault.enhancedSecurityState
      softDeleteFeatureState: recoveryVault.softDeleteFeatureState
      storageModelType: storageType
      storageType: storageType
    }
    backupPolicies: policies
    backupStorageConfig: {
      storageModelType: storageType
      crossRegionRestoreFlag: recoveryVault.crossRegionRestoreFlag
    }
    diagnosticSettings: (diagnosticSettings.diagnosticSettingsEnabled) ? [
      {
        metricCategories: diagnosticSettings.metricCategories
        logAnalyticsDestinationType: 'Dedicated'
        logCategoriesAndGroups: diagnosticSettings.logCategories
        name: 'send-recovery-services-vault-logs-to-law'
        workspaceResourceId: diagnosticSettings.diagnosticsWorkspaceID
      }
    ]:[]
    location: location
    lock: (!empty(lock ?? {}) && lock.?kind != 'None') ? {
      kind: lock.kind
      name: lock.name
    } : {}
    // managedIdentities:{}
    monitoringSettings: {
      azureMonitorAlertSettings:{
        alertsForAllJobFailures: 'Enabled'
      }
      classicAlertSettings:{
        alertsForCriticalOperations: 'Disabled'
      }
    }
    privateEndpoints: (enablePrivateEndpoint && length (PrivateEndpointSubnetID) > 0 ) ? [
      {
        subnetResourceId: PrivateEndpointSubnetID
        service: 'AzureBackup'
        privateDnsZoneGroup: PrivateDNSZoneGroup
      }
    ] : []
    // replicationAlertSettings:
    securitySettings: {
      immutabilitySettings: {
        state: recoveryVault.immutabilityState
      }
      softDeleteSettings:{
        enhancedSecurityState: 'Enabled'
        softDeleteRetentionPeriodInDays: 14
        softDeleteState: 'Enabled'
      }
      multiUserAuthorization: (attachResourceGuard) ? 'Enabled' : 'Disabled'
    }
    // Tags: inherited by policy

    // Non-required parameters (Optional)
    publicNetworkAccess: (enablePrivateEndpoint && length (PrivateEndpointSubnetID) > 0) ? 'Disabled' : 'Enabled'
  }
}

// Module to protect the Recovery Vault with Resource Guard
module resourceguard '../recoveryServices/vault/backupResourceGuardProxy.bicep' = if (attachResourceGuard) {
  name: 'deploy-resource-guard-proxy-${deploymentTime}'
  scope: recoveryVaultRG
  params: {
    resourceGuardId: resourceGuardId
    resourceGuardOperationDetails: resourceGuardOperationDetails
    avm_recoveryVaultname: RSVName
  }
  dependsOn: [
    avm_recoveryVault
  ]
}

//Outputs
output RecoveryServicesVaultName string = avm_recoveryVault.outputs.name
output PrincipalId string = avm_recoveryVault.outputs.systemAssignedMIPrincipalId

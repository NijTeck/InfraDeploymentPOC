// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 01-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-01-03: Initial Commit / MAC Only
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

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

@description ('Optional: Location for the deployment.')
param project string

@description('Recovery Services Vault Name')
param RSVName string

@description('Recovery ServicesVault configuration items')
param recoveryVault object

@description('Recovery Vault & Recovery Vault Restore Resource Group Tags')
param resourceGroupTags object

@description('Backup Storage Type')
param storageType string = 'Standard_GRS'

param StorageTypeShort string = ''

@description('Backup Policy settings to be created in the Recovery Services vault')
param FileBackupPolicies array

/*
@description('Backup Policy settings to be created in the Recovery Services Vault')
param VMBackupPolicies array

@description('Backup Policy settings to be created in the Recovery Services Vault')
param SQLBackupPolicies array

@description('Resource Group Name for the Azure Backup restore Resource Group')
param RestoreResourceGroupName string
*/

@description('Enable Private Endpoint for Recovery Services Vault')
param enablePrivateEndpoint bool = false

@description('Private Endpoint Subnet ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.Network/virtualNetworks/vnetName/subnets/subnetName')
param PrivateEndpointSubnetID string = ''

@description('Private Endpoint DNS Zone ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.Network/privateDnsZones/privateDnsZoneName')
param PrivateEndpointDNSZoneID string = ''

@description('Diagnostic Settings for Recovery Services Vault')
param diagnosticSettings object

targetScope = 'subscription'


var FileBackupPolicySaver = [for policy in FileBackupPolicies:{
  name: policy.name
  properties: {
    backupManagementType: 'AzureStorage'
    workloadType: 'AzureFileShare'
    timeZone: 'Mountain Time'
    protectedItemsCount: 0
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: policy.frequency
      hourlySchedule: (policy.frequency == 'Hourly') ? {
        interval: policy.hourlyFrequency
        scheduleWindowDuratiion: policy.hourlyduration
        scheduleWindowStartTime: policy.startTime
      } : null
      dailySchedule: (policy.frequency == 'Daily') ? {
        scheduleRunTimes: [
          policy.startTime
        ]
      }: null
      ScheduleRunTimes: [
        policy.startTime
      ]
      scheduleWeeklyFrequency: 0
    }
    retentionPolicy: {
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
        retentionTimes: [
          policy.startTime
        ]
        retentionDuration: {
          count: policy.weeklyRetention
          durationType: 'Weeks'
        }
      } : null
      monthlySchedule: (policy.monthlyRetention > 0) ? {
        retentionScheduleFormatType: 'Daily'
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
        retentionDuration: {
          count: policy.monthlyRetention
          durationType: 'Months'
        }
      } : null
      yearlySchedule: (policy.yearlyRetention > 0) ? {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: [
          'January'
        ]
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
        retentionDuration: {
          count: policy.yearlyRetention
          durationType: 'Years'
        }
      } : null
    }
  }
}]

/*
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
        scheduleWindowDuration: policy.hourlyduration
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
        isCompression: true
        issqlcompression: true
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
*/

var policies = concat(FileBackupPolicySaver)
// Creates a Recovery Vault Resource Group

resource recoveryVaultRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${project}-recoveryvault-${loc}-rg'
  location: location
  tags: resourceGroupTags
}

// Module to deploy the Recovery Vault
module avm_recoveryVault 'br/public:avm/res/recovery-services/vault:0.2.2' = {
  name: 'deploy-recovery-vault-${deploymentTime}'
  scope: recoveryVaultRG
  params:{
    name: RSVName
    backupPolicies: policies
    backupConfig: {
      enhancedSecurity: recoveryVault.enhancedSecurityState
      softDeleteFeatureState: recoveryVault.softDeleteFeatureState
      storageModelType: storageType

    }
    backupStorageConfig: {
      storageModelType: storageType
      crossRegionRestoreFlag: recoveryVault.crossRegionRestoreFlag
    }
    securitySettings: {
      immutabilitySettings: {
        state: recoveryVault.immutabilityState
      }
    }
    privateEndpoints: (enablePrivateEndpoint && length (PrivateEndpointSubnetID) > 0 ) ? [
      {
        subnetResourceId: PrivateEndpointSubnetID
        service: 'AzureBackup'
        privateDnsZoneResourceIds: [
          PrivateEndpointDNSZoneID
        ]
      }
    ] : []
    publicNetworkAccess: (enablePrivateEndpoint && length (PrivateEndpointSubnetID) > 0) ? 'Disabled' : 'Enabled'
    monitoringSettings: {
      azureMonitorAlertSettings:{
        alertsForAllJobFailures: 'Enabled'
      }
      classicAlertSettings:{
        alertsForCriticalOperations: 'Disabled'
      }
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
  }
}

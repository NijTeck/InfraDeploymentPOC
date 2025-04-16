// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 01-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - Identify Non-required parameters (Optional) vs (WAF)
// - Update avm/res/storage/storage-account to 0.15.0 or greater
// [Known Issues]
// - None
// [Change Log]
// - 2025-01-03: Initial Commit / MAC Only
//               Added Azure Verified Module references for 1) required parameters, 2) non-required parameters (Optional)
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

param name string

param fileServices object

param kind string

param privateDnsZone string = ''

@description('Private Endpoint Subnet ID - example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rgName/providers/Microsoft.Network/virtualNetworks/vnetName/subnets/subnetName')
param PrivateEndpointSubnetID string = ''

@description('Required: Enter Department or Project Name')
param project string

@description('Required: Storage Account Resource Group Tags')
param resourceGroupTags object

param skuName string

// TARGET
targetScope = 'subscription'

// OUTPUTS

// RESOURCES
// -------------------------------------------------------------------------------------------------------
// Create Storage Resource Group  (Standard Naming Convention)                                           *
// -------------------------------------------------------------------------------------------------------
resource stgAcctRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${project}-storage-${loc}-rg'
  location: location
  tags: resourceGroupTags
}

module avm_stgacct 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: 'deploy-storage-${deploymentTime}'
  scope: stgAcctRG
  params:{
    // Required parameters
    name: name

    // Non-required parameters (Optional)
    blobServices: {
      containerDeleteRetentionPolicyEnabled: false
      containerDeleteRetentionPolicyDays: 7
      deleteRetentionPolicyEnabled: false
      deleteRetentionPolicyDays: 6
    }

    // File Share Declaration - Define Soft Delete - Protocol - Access Tier - Share name - and quota for each share in the share array
    fileServices: fileServices

    // Optionally enable private endpoint by keeping this parameter block
    privateEndpoints: [
      {
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZone
            }
          ]
        }
        service: 'file'
        subnetResourceId: PrivateEndpointSubnetID
      }
    ]

    // StorageV2 or FileStorage for Premium
    kind: kind
    location: location

    // With Kind==StorageV2 ->   Standard_LRS, Standard_ZRS, Standard_GRS, Standard_GZRS, Standard_RAGRS, Standard_RAGZRS With Kind==FileStorage -> Premium_LRS, Premium_ZRS
    skuName: skuName

    // AVM defaults to true
    requireInfrastructureEncryption: false

    // Defaults to Disabled which is now a non-standard deployment
    largeFileSharesState: 'Enabled'


  }
}

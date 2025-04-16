// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 02-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-02-03: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER
param resourceGuardId string

param avm_backupVaultname string

param resourceGuardOperationDetails array

// VARIABLES

// TARGET
targetScope = 'resourceGroup'

// OUTPUTS

// RESOURCES
resource backupVault 'Microsoft.DataProtection/backupVaults@2024-04-01' existing = {
  name: avm_backupVaultname
}

resource rsvresourceguardproxy 'Microsoft.DataProtection/backupVaults/backupResourceGuardProxies@2024-04-01' = {
  name: 'DppResourceGuardProxy'
  parent: backupVault
  properties:{
    resourceGuardResourceId: resourceGuardId
    resourceGuardOperationDetails:resourceGuardOperationDetails

  }
}

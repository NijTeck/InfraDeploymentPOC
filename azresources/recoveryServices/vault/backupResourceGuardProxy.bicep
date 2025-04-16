// ---------------------------------------------------------------------------------------------------------
// Copyright (c) 02-2025 Enterprise Technology, Cloud & Systems Infrastructure, All Rights Reserved.       *
// ---------------------------------------------------------------------------------------------------------
// [Backlog Issues]
// - None
// [Known Issues]
// - None
// [Change Log]
// - 2025-02-07: Initial Commit
// ---------------------------------------------------------------------------------------------------------

// PARAMETER

param resourceGuardId string

param avm_recoveryVaultname string

param resourceGuardOperationDetails array

// VARIABLES

// TARGET
targetScope = 'resourceGroup'

// OUTPUTS

// RESOURCES
resource rsv 'Microsoft.RecoveryServices/vaults@2024-10-01' existing =  {
  name: avm_recoveryVaultname
}

resource rsvresourceguardproxy 'Microsoft.RecoveryServices/vaults/backupResourceGuardProxies@2024-10-01' = {
  name: 'VaultProxy'
  parent: rsv
  properties:{
    resourceGuardResourceId: resourceGuardId
    resourceGuardOperationDetails:resourceGuardOperationDetails
  }
}


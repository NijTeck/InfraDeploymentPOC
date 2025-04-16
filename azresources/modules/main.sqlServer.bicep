@description('The location for all resources')
param location string

@description('The environment name')
param environment string

@description('The virtual network ID')
param virtualNetworkId string

@description('The private DNS zone IDs')
param privateDnsZones object

@description('The storage container path for vulnerability assessments')
@secure()
param vulnerabilityAssessmentsStorageContainerPath string

var sqlServerName = 'pci-${environment}-cus-ncp-web-sql'
var privateEndpointName = 'pci-${environment}-cus-ncp-web-sql-pe'

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    Environment: environment
    Creator: 'Lesere, azadm, azadm.lesere@flyfrontier.onmicrosoft.com'
    ReviewDate: '01/22/2026'
    Diagnostics: 'true'
    DateCreated: '01/22/2025'
  }
  kind: 'v12.0'
  properties: {
    administratorLogin: 'ncpsqladmin'
    version: '12.0'
    minimalTlsVersion: 'None'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
      login: 'azadm.lesere@flyfrontier.onmicrosoft.com'
      sid: 'e3fa36f3-533e-442c-be94-d1fb03668a6e'
      tenantId: '77ead82d-8a2e-4bc2-b8b3-2f8e0d161f2d'
    }
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: {
    Environment: environment
    Creator: 'Lesere, azadm, azadm.lesere@flyfrontier.onmicrosoft.com'
    ReviewDate: '01/22/2026'
    Diagnostics: 'true'
    DateCreated: '01/22/2025'
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${sqlServerName}-connection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: '${virtualNetworkId}/subnets/f9pcitstcusinternalpesn'
    }
  }
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink_database_windows_net'
        properties: {
          privateDnsZoneId: privateDnsZones.sqlServer
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

resource identityWebDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: 'identity-web'
  location: location
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 2
  }
  kind: 'v12.0,user,vcore'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 34359738368
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    licenseType: 'LicenseIncluded'
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Geo'
    maintenanceConfigurationId: '/subscriptions/31e73e1a-7952-45fe-8e41-8a1316446905/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/SQL_Default'
    isLedgerOn: false
    availabilityZone: 'NoPreference'
  }
}

output sqlServerName string = sqlServerName
output sqlServerId string = sqlServer.id 

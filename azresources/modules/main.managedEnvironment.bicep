@description('The location for all resources')
param location string

@description('The environment name')
param environment string

@description('The virtual network ID')
param virtualNetworkId string

@description('The private DNS zone IDs')
param privateDnsZones object

var managedEnvironmentName = 'pci-${environment}-cus-ncp-web-cae'
var nsgName = 'pci-${environment}-cus-ncp-web-nsg'
var privateEndpointName = 'pci-${environment}-cus-ncp-web-cae-pe'

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: managedEnvironmentName
  location: location
  tags: {
    Environment: environment
    Diagnostics: 'true'
    DateCreated: '01/22/2025'
    ReviewDate: '01/22/2026'
    Creator: 'Lesere, azadm, azadm.lesere@flyfrontier.onmicrosoft.com'
  }
  properties: {
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: '${virtualNetworkId}/subnets/pci-${environment}-cus-ncp-web-snet'
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: '6c0fbee3-1576-4c19-926e-098fa9070cba'
        dynamicJsonColumns: false
      }
    }
    zoneRedundant: false
    kedaConfiguration: {}
    daprConfiguration: {}
    customDomainConfiguration: {}
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
        enableFips: false
      }
    ]
    infrastructureResourceGroup: 'ME_${managedEnvironmentName}_pci-${environment}-cus-ncp-web-rg_centralus'
    peerAuthentication: {
      mtls: {
        enabled: false
      }
    }
    peerTrafficConfiguration: {
      encryption: {
        enabled: false
      }
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  tags: {
    Environment: environment
    Creator: 'Lesere, azadm, azadm.lesere@flyfrontier.onmicrosoft.com'
    ReviewDate: '01/22/2026'
    Diagnostics: 'true'
    DateCreated: '01/22/2025'
  }
  properties: {
    securityRules: [
      {
        name: 'AllowAnyFromF910_0_0_0_8'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '10.0.0.0/8'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: {
    Environment: environment
    DateCreated: '04/07/2025'
    ReviewDate: '04/07/2026'
    Diagnostics: 'true'
    Creator: 'Lesere, azadm, azadm.lesere@flyfrontier.onmicrosoft.com'
  }
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: managedEnvironment.id
          groupIds: [
            'managedEnvironments'
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
      id: '${virtualNetworkId}/subnets/f9pcitstcusinternaldmzpesn'
    }
  }
}

resource privateEndpointDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-centralus-azurecontainerapps-io'
        properties: {
          privateDnsZoneId: privateDnsZones.azureContainerApps
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

output managedEnvironmentId string = managedEnvironment.id
output managedEnvironmentName string = managedEnvironmentName 

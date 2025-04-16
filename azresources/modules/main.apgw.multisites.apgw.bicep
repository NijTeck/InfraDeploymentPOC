param applicationGateways_prod_multisites_apgw_name string = 'prod-multisites-apgw'
param virtualNetworks_f9pciprdcusdmzvnet_externalid string = '/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/virtualNetworks/f9pciprdcusdmzvnet'
param publicIPAddresses_prod_multisites_agw_pip_externalid string = '/subscriptions/f29676ff-3153-46e4-956e-3134a7bdaba4/resourceGroups/f9pciprdcusnetrg/providers/Microsoft.Network/publicIPAddresses/prod-multisites-agw-pip'

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: applicationGateways_prod_multisites_apgw_name
  location: 'centralus'
  tags: {
    Department: 'CTS'
    Environment: 'Production'
    DateCreated: '03/20/2025'
    Diagnostics: 'true'
    Creator: 'Harak, Azadm Sagar, azadm.sharak@flyfrontier.onmicrosoft.com'
    ReviewDate: '03/20/2026'
    DateLastModified: '03/20/2025'
    LastModifiedBy: 'Harak, Azadm Sagar, azadm.sharak@flyfrontier.onmicrosoft.com'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      // Removed 'family' property as it's not allowed
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId(split(virtualNetworks_f9pciprdcusdmzvnet_externalid, '/')[2], split(virtualNetworks_f9pciprdcusdmzvnet_externalid, '/')[4], 'Microsoft.Network/virtualNetworks/subnets', split(virtualNetworks_f9pciprdcusdmzvnet_externalid, '/')[8], 'f9pciprdcusdmzapimagwsn')
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'agency.flyfrontier.com'
        properties: {}
      }
    ]
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIpIPv4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_prod_multisites_agw_pip_externalid
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'agency-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: 'prdndc-agencyui.kindgrass-99ab5feb.centralus.azurecontainerapps.io'
            }
          ]
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'prod-agency-backend-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGateways_prod_multisites_apgw_name, 'prod-agency-backend-probe')
          }
        }
      }
    ]
    backendSettingsCollection: []
    httpListeners: [
      {
        name: 'agency-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateways_prod_multisites_apgw_name, 'appGwPublicFrontendIpIPv4')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateways_prod_multisites_apgw_name, 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGateways_prod_multisites_apgw_name, 'agency.flyfrontier.com')
          }
          hostName: 'agency.flyfrontier.com'
          hostNames: []
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
    ]
    listeners: []
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'agency-route'
        properties: {
          ruleType: 'Basic'
          priority: 1000
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateways_prod_multisites_apgw_name, 'agency-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateways_prod_multisites_apgw_name, 'agency-backend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateways_prod_multisites_apgw_name, 'prod-agency-backend-settings')
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: 'prod-agency-backend-probe'
        properties: {
          protocol: 'Https'
          path: '/status-0123456789abcdef'
          interval: 60
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-504'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
}

output applicationGatewayId string = applicationGateway.id
output applicationGatewayName string = applicationGateway.name

@description('The location for all resources')
param location string

@description('The environment name')
param environment string

@description('The managed environment ID')
param managedEnvironmentId string

@description('The SQL server name')
param sqlServerName string

@description('The storage account name')
param storageAccountName string

var containerApps = [
  {
    name: 'tstncpweb-corpsiteweb'
    image: 'pcitstcusncpcr.azurecr.io/corpsiteweb:298083'
    daprAppId: 'corpsite-web'
  }
  {
    name: 'tstncpweb-identityweb'
    image: 'pcitstcusncpcr.azurecr.io/identityweb:297987'
    daprAppId: 'identity-web'
  }
  {
    name: 'tstncpweb-flyfrontierweb'
    image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    daprAppId: 'flyfrontier-web'
  }
  {
    name: 'tstncpweb-identityadminweb'
    image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    daprAppId: 'identityadmin-web'
  }
]

// Create a symbolic reference to the managed environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-10-02-preview' existing = {
  name: managedEnvironmentId
}

resource daprPubSub 'Microsoft.App/managedEnvironments/daprComponents@2024-10-02-preview' = {
  parent: managedEnvironment
  name: 'daprpubsubnotificationevent'
  properties: {
    componentType: 'pubsub.azure.eventhubs'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    secrets: [
      {
        name: 'connectionstring'
      }
    ]
    metadata: [
      {
        name: 'consumerGroup'
        value: 'pushnotificationcg'
      }
      {
        name: 'storageAccountName'
        value: 'pcistgcusndcwebst'
      }
      {
        name: 'storageContainerName'
        value: 'pcistgcusndcwebst-cont1'
      }
      {
        name: 'connectionString'
        value: 'pcistgcusndcwebstpcistgcusndcwebstpcistgcusndcwebst'
      }
      {
        name: 'storageConnectionString'
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=core.windows.net;AccountKey=OYasPKrr3B04r6Trc0YlBfQmzP0Xziw25VBU5eDdnaOU++i/FOn5/zN+Tr2JtMt5PffkwaDaz7/M+AStVICOSQ=='
      }
    ]
    scopes: [
      'notificationemitter-mic'
      'eventreceiver-evt'
    ]
  }
}

resource containerAppResources 'Microsoft.App/containerapps@2024-10-02-preview' = [for app in containerApps: {
  name: app.name
  location: location
  tags: {
    Environment: environment
    DateCreated: '01/22/2025'
    Creator: 'Lesere, azadm, azadm.lesere@flyfrontier.onmicrosoft.com'
    ReviewDate: '01/22/2026'
    Diagnostics: 'true'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: managedEnvironmentId
    environmentId: managedEnvironmentId
    workloadProfileName: 'Consumption'
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: app.name == 'tstncpweb-identityweb'
        clientCertificateMode: 'Ignore'
        stickySessions: {
          affinity: 'none'
        }
      }
      registries: [
        {
          server: 'pcitstcusncpcr.azurecr.io'
          username: 'pcitstcusncpcr'
          passwordSecretRef: 'container-registry-password'
        }
      ]
      identitySettings: []
      dapr: {
        enabled: true
        appId: app.daprAppId
        appProtocol: 'http'
        logLevel: 'debug'
        enableApiLogging: true
      }
      maxInactiveRevisions: 2
    }
    template: {
      containers: [
        {
          image: app.image
          imageType: 'ContainerImage'
          name: app.name
          env: [
            {
              name: 'AZP_URL'
              value: 'https://dev.azure.com/flyfrontier'
            }
            {
              name: 'baseURL'
              value: 'https://${app.name}.${az.environment().suffixes.azureFrontDoorEndpointSuffix}'
            }
            {
              name: 'mssqlConnectionString'
              value: 'jdbc:sqlserver://${sqlServerName}.${az.environment().suffixes.sqlServerHostname}:1433;database=identity-web;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.${az.environment().suffixes.sqlServerHostname};loginTimeout=30;'
            }
            {
              name: 'mssqlUsername'
              value: 'tstncpadmin'
            }
            {
              name: 'mssqlPassword'
              value: 'FtWCDqwRkm7hr74o'
            }
            {
              name: 'mssqlServer'
              value: '${sqlServerName}.${az.environment().suffixes.sqlServerHostname},1433'
            }
            {
              name: 'mssqlDatabaseName'
              value: 'identity-web'
            }
            {
              name: 'keyVaultUrl'
              value: 'https://f9pcitstcusmtierkv.${az.environment().suffixes.keyvaultDns}'
            }
            {
              name: 'naviTokenServiceHost'
              value: 'tstncp-navitairetokensvc.${az.environment().suffixes.azureFrontDoorEndpointSuffix}'
            }
            {
              name: 'naviTokenServiceEndpoint'
              value: 'https://tstncp-navitairetokensvc.${az.environment().suffixes.azureFrontDoorEndpointSuffix}'
            }
            {
              name: 'naviTokenServicePort'
              value: '443'
            }
            {
              name: 'environment'
              value: environment
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        cooldownPeriod: 300
        pollingInterval: 30
      }
    }
  }
}] 
